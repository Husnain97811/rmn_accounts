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

  @override
  void initState() {
    super.initState();
    // Rebuild the UI when search text changes so filtering happens in real-time
    _searchController.addListener(() {
      setState(() {});
    });

    // Trigger the initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() async {
    final loadingProvider = context.read<LoadingProvider>();
    final cashFlowProvider = context.read<CashFlowProvider>();

    loadingProvider.startLoading();
    try {
      await cashFlowProvider.loadWalletBalance();
    } finally {
      loadingProvider.stopLoading();
    }
  }

  // This helper function derives the data directly from the provider
  List<WalletTransaction> _getProcessedTransactions(CashFlowProvider provider) {
    // 1. Get ONLY credit transactions from wallet system
    final walletCredits =
        provider.walletTransactions.where((t) => t.type == 'credit').toList();

    // 2. Get wallet expenses from cash flow transactions
    final walletExpenses =
        provider.transactions.where((t) => t.type == 'wallet expense').toList();

    // 3. Convert wallet expenses to WalletTransaction format
    final convertedExpenses =
        walletExpenses.map((expense) {
          return WalletTransaction(
            id: int.parse(expense.id),
            amount: expense.amount,
            type: 'debit',
            description: expense.description ?? 'Wallet Expense',
            createdAt: expense.date,
          );
        }).toList();

    // 4. Combine them
    final combinedTransactions = [...walletCredits, ...convertedExpenses];

    // 5. Filter based on Search Controller
    final filtered =
        _searchController.text.isEmpty
            ? combinedTransactions
            : combinedTransactions.where((transaction) {
              final description = transaction.description?.toLowerCase() ?? '';
              final searchText = _searchController.text.toLowerCase();
              return description.contains(searchText);
            }).toList();

    // 6. Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
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
                // We don't need logic here because the listener in initState handles the rebuild
                onChanged: (value) {},
                hintText: 'Search by description',
              ),
              Expanded(
                child: Consumer<CashFlowProvider>(
                  builder: (context, provider, _) {
                    // Calculate the list dynamically inside the builder
                    final transactions = _getProcessedTransactions(provider);

                    if (transactions.isEmpty) {
                      return EmptyStateWidget(
                        message: 'No wallet transactions found',
                        searchQuery: _searchController.text,
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(2.w),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return WalletTransactionTile(
                          transaction: transaction,
                          onTap:
                              () =>
                                  _showTransactionDetails(context, transaction),
                        );
                      },
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
    final source =
        transaction.description?.contains('Wallet Expense') ?? false
            ? 'Cash Flow System'
            : 'Wallet System';

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
                label: 'Source:',
                value: source,
                valueColor: Colors.purple,
              ),
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
      // No need to manually update transactions, Consumer handles it
    });
  }

  void _generateWalletPdfWithTimeFilter(BuildContext context) {
    // First, show dialog to select transaction type
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Report Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.arrow_downward,
                    color: Colors.green,
                  ),
                  title: const Text('Income Report'),
                  subtitle: const Text('Only wallet credit transactions'),
                  onTap: () {
                    Navigator.pop(context, 'income');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward, color: Colors.red),
                  title: const Text('Expense Report'),
                  subtitle: const Text('Only wallet expense transactions'),
                  onTap: () {
                    Navigator.pop(context, 'expense');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.compare_arrows, color: Colors.blue),
                  title: const Text('Combined Report'),
                  subtitle: const Text('Both income and expense transactions'),
                  onTap: () {
                    Navigator.pop(context, 'both');
                  },
                ),
              ],
            ),
          ),
    ).then((selectedType) {
      if (selectedType != null) {
        // After selecting type, show time interval selection
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

              // Get all transactions first
              List<WalletTransaction> walletCredits =
                  cashFlowProvider.walletTransactions
                      .where((t) => t.type == 'credit')
                      .toList();

              List<CashFlowTransaction> walletExpenses =
                  cashFlowProvider.transactions
                      .where((t) => t.type == 'wallet expense')
                      .toList();

              // Filter based on selected type
              if (selectedType == 'income') {
                // Only income - set expenses to empty
                walletExpenses = [];
              } else if (selectedType == 'expense') {
                // Only expense - set credits to empty
                walletCredits = [];
              }
              // If 'both', keep both lists as is

              final file = await PdfService.generateWalletReport(
                walletCredits: walletCredits,
                walletExpenses: walletExpenses,
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
    });
  }
}
