import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/transaction_entries_components.dart';
import 'package:rmn_accounts/utils/views.dart';

class CashFlowEntriesScreen extends StatefulWidget {
  const CashFlowEntriesScreen({super.key});

  @override
  State<CashFlowEntriesScreen> createState() => _CashFlowEntriesScreenState();
}

class _CashFlowEntriesScreenState extends State<CashFlowEntriesScreen>
    with RefreshableScreen {
  final TextEditingController _searchController = TextEditingController();

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
      await cashFlowProvider.loadTransactions();
    } finally {
      loadingProvider.stopLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Entries'),
          backgroundColor: const Color.fromARGB(78, 36, 36, 62),
          actions: [
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
                    (value) =>
                        context.read<CashFlowProvider>().setSearchQuery(value),
                hintText: 'Search by name or description',
              ),
              Expanded(
                child: Consumer<CashFlowProvider>(
                  builder: (context, provider, _) {
                    if (provider.filteredTransactions.isEmpty) {
                      return EmptyStateWidget(
                        message: 'No transactions found',
                        searchQuery: _searchController.text,
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.all(2.w),
                      itemCount: provider.filteredTransactions.length,
                      itemBuilder:
                          (context, index) => CashFlowTransactionTile(
                            transaction: provider.filteredTransactions[index],
                            onEdit:
                                () => _showTransactionDialog(
                                  context,
                                  transaction:
                                      provider.filteredTransactions[index],
                                ),

                            // if i delete employee commission paid transaction, it should reverse operation like deduct the deleted transaction amount from commission paid and re add to  the commission_unpaid from employee
                            onDelete:
                                () => provider.deleteTransaction(
                                  int.parse(
                                    provider.filteredTransactions[index].id,
                                  ),
                                  context,
                                  transaction:
                                      provider
                                          .filteredTransactions[index], // Add this line
                                ),
                            onTap:
                                () => _showTransactionDetails(
                                  context,
                                  provider.filteredTransactions[index],
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
    CashFlowTransaction transaction,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => TransactionDetailsDialog(
            title: 'Transaction Details',
            details: [
              DetailRow(
                label: 'Amount:',
                value: transaction.amount.toStringAsFixed(2),
              ),

              if (transaction.employeeId != null)
                DetailRow(
                  label: 'Employee Commision:',
                  value: transaction.commission.toString(),
                ),

              DetailRow(label: 'Type:', value: transaction.type.toUpperCase()),
              DetailRow(label: 'Category:', value: transaction.category),
              DetailRow(label: 'Description:', value: transaction.description),
              DetailRow(
                label: 'Date:',
                value: DateFormatters.formatFullDate(transaction.date),
              ),
              if (transaction.employeeName != null)
                DetailRow(label: 'Employee:', value: transaction.employeeName!),
              if (transaction.employeeId != null)
                DetailRow(
                  label: 'Employee ID:',
                  value: transaction.employeeId!,
                ),
            ],
          ),
    );
  }

  void _refreshData() {
    refreshData(() => context.read<CashFlowProvider>().loadTransactions());
  }

  void _showTransactionDialog(
    BuildContext context, {
    CashFlowTransaction? transaction,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => TransactionForm(transaction: transaction),
    ).then((_) => context.read<CashFlowProvider>().loadTransactions());
  }
}
