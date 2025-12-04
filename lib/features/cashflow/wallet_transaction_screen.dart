import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/views.dart';

import '../../utils/pdf_service.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  State<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen>
    with RefreshableScreen {
  final TextEditingController _searchController = TextEditingController();
  List<WalletTransaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final loadingProvider = context.read<LoadingProvider>();
    final cashFlowProvider = context.read<CashFlowProvider>();

    loadingProvider.startLoading();
    try {
      await cashFlowProvider.loadWalletBalance();
      _updateFilteredTransactions(cashFlowProvider.walletTransactions);
    } finally {
      loadingProvider.stopLoading();
    }
  }

  void _updateFilteredTransactions(List<WalletTransaction> transactions) {
    setState(() {
      _filteredTransactions =
          _searchController.text.isEmpty
              ? transactions
              : transactions.where((transaction) {
                return transaction.description.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
              }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wallet Transactions'),
          backgroundColor: const Color.fromARGB(78, 36, 36, 62),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () => _generateWalletPdfWithTimeFilter(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: buildGradientBackground(
          child: Column(
            children: [
              SearchBarWidget(
                controller: _searchController,
                onChanged:
                    (value) => _updateFilteredTransactions(
                      context.read<CashFlowProvider>().walletTransactions,
                    ),
                hintText: 'Search by description',
              ),
              // Consumer<CashFlowProvider>(
              //   builder:
              //       (context, provider, _) => BalanceCard(
              //         title: 'Current Balance:',
              //         balance: provider.walletBalance,
              //         balanceColor:
              //             provider.walletBalance >= 0
              //                 ? Colors.green
              //                 : Colors.red,
              //       ),
              // ),
              Expanded(
                child: Consumer<CashFlowProvider>(
                  builder: (context, provider, _) {
                    if (provider.walletTransactions.isEmpty) {
                      return EmptyStateWidget(
                        message: 'No wallet transactions found',
                        searchQuery: _searchController.text,
                      );
                    }

                    if (_filteredTransactions.isEmpty) {
                      return EmptyStateWidget(
                        message: 'No wallet transactions found',
                        searchQuery: _searchController.text,
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(2.w),
                      itemCount: _filteredTransactions.length,
                      itemBuilder:
                          (context, index) => WalletTransactionTile(
                            transaction: _filteredTransactions[index],
                            onTap:
                                () => _showTransactionDetails(
                                  context,
                                  _filteredTransactions[index],
                                ),
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    WalletTransaction transaction,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => TransactionDetailsDialog(
            title: 'Wallet Transaction Details',
            details: [
              DetailRow(
                label: 'Amount:',
                value:
                    '${transaction.type == 'credit' ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                valueColor:
                    transaction.type == 'credit' ? Colors.green : Colors.red,
              ),
              DetailRow(
                label: 'Type:',
                value: transaction.type.toUpperCase(),
                valueColor: Colors.blue,
              ),
              DetailRow(label: 'Description:', value: transaction.description),
              DetailRow(
                label: 'Date:',
                value: DateFormatters.formatDateOnly(transaction.createdAt),
                valueColor: Colors.black54,
              ),
              DetailRow(
                label: 'Time:',
                value: DateFormatters.formatTimeOnly(transaction.createdAt),
                valueColor: Colors.black54,
              ),
            ],
          ),
    );
  }

  void _refreshData() {
    refreshData(() async {
      await context.read<CashFlowProvider>().loadWalletBalance();
      _updateFilteredTransactions(
        context.read<CashFlowProvider>().walletTransactions,
      );
    });
  }

  void _generateWalletPdfWithTimeFilter(BuildContext context) {
    PdfService.showWalletTimeSelectionDialog(
      context,
      onTimeSelected: (String timeframe, DateTimeRange? dateRange) async {
        final loadingProvider = Provider.of<LoadingProvider>(
          context,
          listen: false,
        );
        final cashFlowProvider = Provider.of<CashFlowProvider>(
          context,
          listen: false,
        );

        try {
          loadingProvider.startPdfLoading();

          final file = await PdfService.generateWalletReport(
            transactions: cashFlowProvider.walletTransactions,
            currentBalance: cashFlowProvider.walletBalance,
            timeframe: timeframe,
            dateRange: dateRange,
          );

          SupabaseExceptionHandler.showSuccessSnackbar(
            context,
            'Wallet PDF generated successfully!\nSaved to: ${file.path}',
          );
        } catch (e) {
          SupabaseExceptionHandler.showErrorSnackbar(
            context,
            'Error generating PDF: ${e.toString()}',
          );
        } finally {
          loadingProvider.stopPdfLoading();
        }
      },
    );
  }

  Future<void> _generateWalletPdf(BuildContext context) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    final cashFlowProvider = Provider.of<CashFlowProvider>(
      context,
      listen: false,
    );

    try {
      loadingProvider.startPdfLoading();

      final file = await PdfService.generateWalletReport(
        transactions: cashFlowProvider.walletTransactions,
        currentBalance: cashFlowProvider.walletBalance,
      );

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Wallet PDF generated successfully!\nSaved to: ${file.path}',
      );
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error generating PDF: ${e.toString()}',
      );
    } finally {
      loadingProvider.stopPdfLoading();
    }
  }
}
