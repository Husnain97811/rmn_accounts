import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rmn_accounts/features/cashflow/wallet_transaction_screen.dart';
import 'package:rmn_accounts/utils/views.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../utils/pdf_service.dart'; // Important alias

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen>
        // Add this at the top of your state class
        with
        SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> pdfMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CashFlowProvider>(context, listen: false);
      final loadingProvider = Provider.of<LoadingProvider>(
        context,
        listen: false,
      );

      loadingProvider.startLoading(); // Start loading
      provider.initialize();
      provider
          .loadTransactions()
          .then((_) {
            return provider.loadWalletBalance();
          })
          .then((_) {
            loadingProvider.stopLoading(); // Stop loading when done
            _animationController.forward();
          })
          .catchError((error) {
            loadingProvider.stopLoading(); // Stop loading on error too
          });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: pdfMessengerKey, // Use the global key here
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_image.png',
                fit: BoxFit.cover,
              ),
            ),
            _buildAppBar(),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 7.h),
                  _buildSummaryCards(),
                  SizedBox(height: 12.h),

                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 34,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: .5.h,
                                    horizontal: 2.5.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 250, 168, 37),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  child: Text(
                                    'Balance:',
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Consumer<CashFlowProvider>(
                                  builder:
                                      (context, provider, _) => Text(
                                        '${provider.walletBalance.toStringAsFixed(1)}',

                                        style: TextStyle(
                                          color:
                                              provider.walletBalance >= 1000
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _walletButton(
                                  () => _showAddWalletDialog(context),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: null,
                                    tooltip: 'Add Balance',
                                    color: Colors.white,
                                  ),
                                  Colors.green.shade300,
                                ),
                                SizedBox(width: 9.sp),
                                _walletButton(
                                  () => _showSubtractWalletDialog(context),
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: null,
                                    tooltip: 'Add Expense',
                                    color: Colors.white,
                                  ),
                                  Colors.red.shade300,
                                ),
                                SizedBox(width: 9.sp),
                                _walletButton(
                                  () => _showWalletTransactions(context),
                                  IconButton(
                                    icon: Icon(Icons.list),
                                    onPressed: null,
                                    tooltip: 'Balance Entries',
                                    color: Colors.white,
                                  ),
                                  Colors.blue.shade300,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  _buildChartsSection(context),
                  // Align(
                  //   alignment: Alignment.center,
                  //   child: ,
                  //   // Expanded(
                  //   //   child: FadeTransition(
                  //   //     opacity: _fadeAnimation,
                  //   //     child: Consumer<CashFlowProvider>(
                  //   //       builder: (context, provider, _) {
                  //   //         if (provider.isLoading) {
                  //   //           return const Center(
                  //   //             child: CircularProgressIndicator(),
                  //   //           );
                  //   //         }
                  //   //         return CustomScrollView(
                  //   //           slivers: [
                  //   //             SliverToBoxAdapter(
                  //   //               child: _buildChartsSection(context),
                  //   //             ),
                  //   //           ],
                  //   //         );
                  //   //       },
                  //   //     ),
                  //   //   ),
                  //   // ),
                  // ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add_transaction',
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showTransactionDialog(context),
        ),
      ),
    );
  }

  Widget _walletButton(
    GestureTapCallback ontap,
    IconButton walletIcon,
    Color? buttonColor,
  ) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        height: 24.sp,
        width: 24.sp,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(15.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4.sp,
              offset: Offset(0, 2.sp),
            ),
          ],
        ),
        child: walletIcon,
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color.fromARGB(202, 255, 255, 255),
      height: 24.sp,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 23.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CashFlow',
            style: TextStyle(
              fontSize: 15.sp,
              // color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Categories',
                icon: Icon(Icons.category, color: Colors.black, size: 17.sp),
                onPressed: _showManageCategories,
              ),
              Consumer<CashFlowProvider>(
                builder:
                    (context, provider, _) => IconButton(
                      tooltip: 'Show/Hide Amounts',
                      icon: Icon(
                        provider.amountsVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                        size: 17.sp,
                      ),
                      onPressed: () => provider.toggleAmountVisibility(),
                    ),
              ),
              IconButton(
                tooltip: 'All Entries',
                icon: Icon(Icons.list, color: Colors.black, size: 17.sp),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CashFlowEntriesScreen(),
                      ),
                    ),
              ),
              Consumer<CashFlowProvider>(
                builder:
                    (context, provider, _) => IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.black,
                        size: 17.sp,
                      ),
                      onPressed: () {
                        final loadingProvider = Provider.of<LoadingProvider>(
                          context,
                          listen: false,
                        );
                        loadingProvider.startLoading();
                        provider
                            .loadTransactions()
                            .then((_) {
                              loadingProvider.stopLoading();
                            })
                            .catchError((error) {
                              loadingProvider.stopLoading();
                            });
                      },
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<CashFlowProvider>(
      builder: (context, provider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryCard(
              'Income',
              provider.totalIncome,
              Colors.green,
              context,
            ),
            SizedBox(width: 32.sp),

            _buildSummaryCard(
              'Expense',
              provider.totalExpense,
              Colors.red,
              context,
            ),
            SizedBox(width: 32.sp),

            _buildSummaryCard(
              'Net Cash Flow',
              provider.totalIncome - provider.totalExpense,
              Colors.blue,
              context,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    BuildContext context,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showReportOptions(context, title),
        child: Container(
          height: 28.h,
          child: Card(
            color: const Color.fromARGB(201, 255, 255, 255),
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: .5.h,
                      horizontal: 1.w,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 250, 168, 37),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),

                  Consumer<CashFlowProvider>(
                    builder:
                        (context, provider, _) => Text(
                          provider.amountsVisible
                              ? '${amount.toStringAsFixed(0)}'
                              : '****',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add to Wallet'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final amountText = amountController.text.trim();
                  if (amountText.isEmpty) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Please enter an amount',
                    );
                    return;
                  }

                  final amount = double.tryParse(amountText);
                  if (amount == null || amount <= 0) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Please enter a valid amount greater than 0',
                    );
                    return;
                  }

                  try {
                    final loadingProvider = Provider.of<LoadingProvider>(
                      context,
                      listen: false,
                    );
                    final cashFlowProvider = Provider.of<CashFlowProvider>(
                      context,
                      listen: false,
                    );

                    loadingProvider.startLoading();

                    await cashFlowProvider.addToWallet(
                      amount,
                      descriptionController.text.trim(),
                    );

                    Navigator.pop(context);
                    SupabaseExceptionHandler.showSuccessSnackbar(
                      context,
                      '${amount.toStringAsFixed(2)} added to wallet successfully!',
                    );
                  } catch (e) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Error: ${e.toString().replaceAll('Exception: ', '')}',
                    );
                  } finally {
                    final loadingProvider = Provider.of<LoadingProvider>(
                      context,
                      listen: false,
                    );
                    loadingProvider.stopLoading();
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showSubtractWalletDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Subtract from Wallet'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<CashFlowProvider>(
                  builder:
                      (context, provider, _) => Text(
                        'Available Balance: ${provider.walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final amountText = amountController.text.trim();
                  if (amountText.isEmpty) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Please enter an amount',
                    );
                    return;
                  }

                  final amount = double.tryParse(amountText);
                  if (amount == null || amount <= 0) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Please enter a valid amount greater than 0',
                    );
                    return;
                  }

                  try {
                    final loadingProvider = Provider.of<LoadingProvider>(
                      context,
                      listen: false,
                    );
                    final cashFlowProvider = Provider.of<CashFlowProvider>(
                      context,
                      listen: false,
                    );

                    loadingProvider.startLoading();

                    await cashFlowProvider.subtractFromWallet(
                      amount,
                      descriptionController.text.trim(),
                    );

                    Navigator.pop(context);
                    SupabaseExceptionHandler.showSuccessSnackbar(
                      context,
                      '${amount.toStringAsFixed(2)} subtracted from wallet successfully!',
                    );
                  } catch (e) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Error: ${e.toString().replaceAll('Exception: ', '')}',
                    );
                  } finally {
                    final loadingProvider = Provider.of<LoadingProvider>(
                      context,
                      listen: false,
                    );
                    loadingProvider.stopLoading();
                  }
                },
                child: Text('Add Expense'),
              ),
            ],
          ),
    );
  }

  void _showWalletTransactions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WalletTransactionsScreen()),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Consumer<CashFlowProvider>(
      builder: (context, provider, _) {
        final income = provider.totalIncome;
        final expense = provider.totalExpense;
        final netCash = income - expense;
        final total = income + expense + netCash.abs();

        if (total == 0) {
          return SizedBox(
            height: 25.h,
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.only(top: 3.h),
            child: Card(
              color: Colors.white,
              child: Container(
                padding: EdgeInsets.all(12.sp),
                height: 32.h,
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildCashFlowBarChart(income, expense, netCash),
                    ),
                    Expanded(flex: 3, child: _buildNetCashPieChart(provider)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashFlowBarChart(double income, double expense, double netCash) {
    final maxY = [
      income,
      expense,
      netCash.abs(),
    ].reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: true),
        maxY: maxY * 1.2,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barsSpace: 0.4,
            barRods: [
              BarChartRodData(
                toY: income,
                color: Colors.green,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barsSpace: 0.4,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: Colors.red,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barsSpace: 0.4,
            barRods: [
              BarChartRodData(
                toY: netCash.abs(),
                color: netCash >= 0 ? Colors.blue : Colors.orange,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text('Income', style: TextStyle(fontSize: 10.sp));
                  case 1:
                    return Text('Expense', style: TextStyle(fontSize: 10.sp));
                  case 2:
                    return Text('Net Cash', style: TextStyle(fontSize: 10.sp));
                  default:
                    return Text('');
                }
              },
              reservedSize: 35,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildNetCashPieChart(CashFlowProvider provider) {
    double income = provider.totalIncome;
    double expense = provider.totalExpense;
    double netCash = income - expense;
    double total = income + expense + netCash.abs();

    if (total == 0) {
      return SizedBox(
        height: 25.h,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    List<PieChartSectionData> sections = [
      PieChartSectionData(
        color: Colors.green,
        value: income,
        title: '${((income / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: expense,
        title: '${((expense / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // PieChartSectionData(
      //   color: netCash >= 0 ? Colors.blue : Colors.orange,
      //   value: netCash.abs(),
      //   title: '${((netCash.abs() / total) * 100).toStringAsFixed(1)}%',
      //   radius: 100,
      //   titleStyle: TextStyle(
      //     fontSize: 12.sp,
      //     fontWeight: FontWeight.bold,
      //     color: Colors.white,
      //   ),
      // ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        child: Card(
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 5.sp),

            height: 32.h,
            width: 77.w,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(enabled: true),
                sections: sections,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(String type, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...categories
            .map(
              (category) => ListTile(
                title: Text(category),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 15.sp),
                  onPressed:
                      () => _deleteCategory(category, type.toLowerCase()),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Future<void> _deleteCategory(String category, String type) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    try {
      loadingProvider.startLoading();
      final provider = Provider.of<CashFlowProvider>(context, listen: false);
      await provider.deleteCategory(category, type);
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Category Deleted Successfully',
      );
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error Deleting Category\nIf problem persists, contact developer',
      );
    } finally {
      loadingProvider.stopLoading();
    }
  }

  void _showAddCategoryDialog() {
    final categoryController = TextEditingController();
    String? selectedType = 'income';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Category Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items:
                      ['income', 'expense']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => selectedType = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (categoryController.text.isNotEmpty &&
                      selectedType != null) {
                    try {
                      final loadingProvider = Provider.of<LoadingProvider>(
                        context,
                        listen: false,
                      );
                      loadingProvider.startLoading();
                      await Provider.of<CashFlowProvider>(
                        context,
                        listen: false,
                      ).addNewCategory(selectedType!, categoryController.text);
                      Navigator.pop(context);
                      SupabaseExceptionHandler.showSuccessSnackbar(
                        context,
                        'Category Added Successfully',
                      );
                    } catch (e) {
                      SupabaseExceptionHandler.showErrorSnackbar(
                        context,
                        e.toString(),
                      );
                    } finally {
                      final loadingProvider = Provider.of<LoadingProvider>(
                        context,
                        listen: false,
                      );
                      loadingProvider.stopLoading();
                    }
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  // Updated _showReportOptions method
  void _showReportOptions(BuildContext context, String reportType) {
    final provider = Provider.of<CashFlowProvider>(context, listen: false);

    provider.loadTransactions().then((_) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Generate $reportType Report'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ADDED NEW TIME RANGE OPTIONS
                    _buildTimeRangeOption(context, reportType, 'Today'),
                    _buildTimeRangeOption(context, reportType, 'Yesterday'),
                    _buildTimeRangeOption(context, reportType, 'This Week'),
                    _buildTimeRangeOption(context, reportType, 'Last Week'),
                    _buildTimeRangeOption(context, reportType, 'This Month'),
                    _buildTimeRangeOption(context, reportType, 'Last Month'),

                    _buildTimeRangeOption(context, reportType, 'Custom Range'),
                  ],
                ),
              ),
            ),
      );
    });
  }

  void _showReportFormatDialog(
    BuildContext context,
    String reportType,
    String timeframe, {
    DateTimeRange? dateRange,
  }) {
    // Use rootNavigator to avoid context from a disposed dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Report Format'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('All Entries'),
                  onTap: () {
                    Navigator.pop(context);
                    _generatePdf(
                      reportType,
                      timeframe,
                      dateRange: dateRange,
                      reportFormat: 'all',
                    );
                  },
                ),
                ListTile(
                  title: Text('Category Wise'),
                  onTap: () {
                    Navigator.pop(context);
                    _generatePdf(
                      reportType,
                      timeframe,
                      dateRange: dateRange,
                      reportFormat: 'category',
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<DateTimeRange?> _selectCustomDateRange(
    BuildContext context,
    String reportType,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context, // Use the passed context
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    return picked;
  }

  void _showManageCategories() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Manage Categories'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Consumer<CashFlowProvider>(
                  builder:
                      (context, provider, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCategoryList(
                            'Income',
                            provider.incomeCategories,
                          ),
                          _buildCategoryList(
                            'Expense',
                            provider.expenseCategories,
                          ),
                        ],
                      ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddCategoryDialog();
                },
                child: Text('Add New'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showTransactionDialog(
    BuildContext context, {
    CashFlowTransaction? transaction,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => TransactionForm(transaction: transaction),
    ).then(
      (_) =>
          Provider.of<CashFlowProvider>(
            context,
            listen: false,
          ).loadTransactions(),
    );
  }

  Future<void> _generatePdf(
    String reportType,
    String timeframe, {
    DateTimeRange? dateRange,
    required String reportFormat,
  }) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    final provider = Provider.of<CashFlowProvider>(context, listen: false);

    try {
      loadingProvider.startPdfLoading();

      if (timeframe == 'custom' && dateRange == null) {
        SupabaseExceptionHandler.showErrorSnackbar(
          context,
          'Please select a valid date range',
        );
        return;
      }

      final transactions = provider.getFilteredTransactions(
        timeframe,
        dateRange,
        reportType,
      );

      final file = await PdfService.generateCashFlowReport(
        reportType: reportType,
        timeframe: timeframe,
        transactions: transactions,
        dateRange: dateRange,
        reportFormat: reportFormat,
      );

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'PDF generated successfully!\nSaved to: ${file.path}',
      );
    } catch (e) {
      final message = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, message.toString());
    } finally {
      loadingProvider.stopPdfLoading();
    }
  }

  // Update the method signature to accept all parameters
  // Future<void> _generatePdf(
  //   String reportType,
  //   String timeframe, {
  //   DateTimeRange? dateRange,
  //   required String reportFormat,
  // }) async {
  //   // REMOVE BuildContext parameter
  //   final loadingProvider = Provider.of<LoadingProvider>(
  //     context,
  //     listen: false,
  //   );

  //   try {
  //     // Add date validation
  //     loadingProvider.startPdfLoading(); // Start loading

  //     if (timeframe == 'custom' && dateRange == null) {
  //       SupabaseExceptionHandler.showErrorSnackbar(
  //         context,
  //         'Please select a valid date range',
  //       );
  //       return;
  //     }

  //     final font = await PdfGoogleFonts.robotoRegular(); // Add dependency

  //     // In _generatePdf()
  //     final provider = Provider.of<CashFlowProvider>(context, listen: false);
  //     // Add reportType parameter here
  //     final transactions = provider.getFilteredTransactions(
  //       timeframe,
  //       dateRange,
  //       reportType,
  //     );

  //     double totalIncome = transactions
  //         .where((t) => t.type == 'income')
  //         .fold(0.0, (sum, t) => sum + t.amount);

  //     double totalExpenses = transactions
  //         .where((t) => t.type == 'expense')
  //         .fold(0.0, (sum, t) => sum + t.amount);

  //     final pdf = pw.Document();
  //     final primaryColor = PdfColors.blueGrey800;

  //     // Add text styles from the design
  //     final titleStyle = pw.TextStyle(
  //       fontWeight: pw.FontWeight.bold,
  //       fontSize: 18.8,
  //       color: PdfColors.black,
  //     );

  //     final subtitleStyle = pw.TextStyle(
  //       fontWeight: pw.FontWeight.bold,
  //       fontSize: 13.8,
  //       color: PdfColors.black,
  //     );
  //     final contentStyle = pw.TextStyle(fontSize: 9, color: PdfColors.black);
  //     final headerStyle = pw.TextStyle(
  //       fontWeight: pw.FontWeight.bold,
  //       fontSize: 11,
  //       color: PdfColors.black,
  //     );

  //     // Net Cashflow Calculations

  //     pdf.addPage(
  //       pw.MultiPage(
  //         pageFormat: PdfPageFormat.a4,
  //         margin: const pw.EdgeInsets.all(32),
  //         header: (pw.Context context) {
  //           if (context.pageNumber == 1) {
  //             return pw.Column(
  //               children: [
  //                 pw.Text(
  //                   'Reliable Marketing Network Pvt Ltd',
  //                   style: titleStyle,
  //                 ),
  //                 pw.SizedBox(height: 4),
  //                 pw.Text('$reportType Report', style: subtitleStyle),

  //                 pw.Divider(color: primaryColor),
  //                 pw.SizedBox(height: 34),
  //               ],
  //             );
  //           }
  //           return pw.SizedBox.shrink();
  //         },
  //         build: (context) {
  //           return [
  //             if (reportType == 'Net Cash Flow') ...[
  //               _buildNetSummary(totalIncome, totalExpenses),
  //               pw.SizedBox(height: 20),
  //               _buildComparisonChart(totalIncome, totalExpenses),
  //               pw.SizedBox(height: 20),
  //               _buildPercentageBreakdown(totalIncome, totalExpenses),
  //               pw.SizedBox(height: 20),
  //               _buildNetResult(totalIncome, totalExpenses),
  //               pw.SizedBox(height: 40),
  //             ] else if (reportFormat == 'category')
  //               ..._buildCategoryWiseContent(transactions, headerStyle)
  //             else
  //               ..._buildAllEntriesContent(
  //                 transactions,
  //                 headerStyle,
  //                 contentStyle,
  //                 reportType,
  //               ),
  //           ];
  //         },
  //         footer:
  //             (pw.Context context) => pw.Container(
  //               alignment: pw.Alignment.centerRight,
  //               margin: const pw.EdgeInsets.only(top: 10),
  //               child: pw.Column(
  //                 crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                 children: [
  //                   _buildSignatureSection(),
  //                   pw.SizedBox(height: 24),
  //                   pw.Text(
  //                     'Period: ${_getDateRangeText(timeframe, dateRange)}',
  //                     style: pw.TextStyle(fontSize: 8),
  //                   ),
  //                   pw.Text(
  //                     'Generated on ${DateFormat.yMd().format(DateTime.now())}',
  //                     style: pw.TextStyle(fontSize: 8),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //       ),
  //     );

  //     // Rest of your existing save PDF code remains unchanged
  //     final directory = await getDownloadsDirectory();
  //     final file = File(
  //       '${directory!.path}/${reportType}_${reportFormat}_${DateTime.now().millisecond.toString()}_report.pdf',
  //     );
  //     await file.writeAsBytes(await pdf.save());
  //     // Show success message using the global key
  //     SupabaseExceptionHandler.showSuccessSnackbar(
  //       context,
  //       'PDF generated successfully!\nSaved to: ${directory.path}',
  //     );
  //   } catch (e) {
  //     final message = SupabaseExceptionHandler.handleSupabaseError(e);
  //     SupabaseExceptionHandler.showErrorSnackbar(context, message.toString());
  //   } finally {
  //     loadingProvider
  //         .stopPdfLoading(); // Stop loading regardless of success/error
  //   }
  // }

  // ================== NET CASHFLOW WIDGETS ================== //
  pw.Widget _buildNetSummary(double income, double expenses) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildPdfSummaryCard('Total Income', income, PdfColors.green),
        _buildPdfSummaryCard('Total Expenses', expenses, PdfColors.red),
      ],
    );
  }

  // PDF-specific summary card for PDF context
  pw.Widget _buildPdfSummaryCard(String title, double amount, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, color: color)),
          pw.SizedBox(height: 5),
          pw.Text(
            '${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildComparisonChart(double income, double expenses) {
    final maxValue = income > expenses ? income : expenses;
    return pw.Container(
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // pw.Text(
          //   'Income vs Expenses Comparison',
          //   style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          // ),
          pw.SizedBox(height: 20),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildBar('Income', income, maxValue, PdfColors.green),
                _buildBar('Expenses', expenses, maxValue, PdfColors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBar(
    String label,
    double value,
    double maxValue,
    PdfColor color,
  ) {
    final barHeight = (value / maxValue) * 120;
    return pw.Expanded(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            height: barHeight,
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.vertical(
                top: pw.Radius.circular(4),
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _formatAmount(absolute: true, amount: value),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _formatAmount({
    bool absolute = false,
    required dynamic amount,
  }) {
    final parsed = _parseAmount(amount);
    final value = absolute ? parsed.abs() : parsed;
    return '${value >= 0 ? '' : '-'} ${value.abs().toStringAsFixed(2)}';
  }

  static double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  static pw.Widget _buildPercentageBreakdown(double income, double expenses) {
    final total = income + expenses;
    final incomePercent = total != 0 ? (income / total) * 100 : 0;
    final expensePercent = total != 0 ? (expenses / total) * 100 : 0;

    return pw.Column(
      children: [
        pw.Text(
          'Income And Expenses Ratio',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 30,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              // percentag bar
              pw.Container(
                width: (incomePercent / 100) * 200, // 200 = max width of bar
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    bottomLeft: pw.Radius.circular(4),
                  ),
                ),
              ),
              pw.Container(
                width: (expensePercent / 100) * 200,
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  borderRadius: const pw.BorderRadius.only(
                    topRight: pw.Radius.circular(4),
                    bottomRight: pw.Radius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Income: ${incomePercent.toStringAsFixed(1)}%',
              style: pw.TextStyle(color: PdfColors.green, fontSize: 12),
            ),
            pw.Text(
              'Expenses: ${expensePercent.toStringAsFixed(1)}%',
              style: pw.TextStyle(color: PdfColors.red, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildNetResult(double income, double expenses) {
    final net = income - expenses;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Net Cashflow: ',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _formatAmount(amount: net),
            style: pw.TextStyle(
              fontSize: 16,
              color: net >= 0 ? PdfColors.green : PdfColors.red,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Align(
      alignment: pw.Alignment.bottomRight,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        // mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            alignment: pw.Alignment.bottomRight,
            width: 150,
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Authorized Signature',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildCategoryWiseContent(
    List<CashFlowTransaction> transactions,
    pw.TextStyle style,
  ) {
    final categoryTotals = <String, double>{};
    double overallTotal = 0.0;

    for (final transaction in transactions) {
      categoryTotals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      overallTotal += transaction.amount;
    }

    // Convert to list for easier manipulation
    final categoryEntries = categoryTotals.entries.toList();

    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 1),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
        children: [
          // Header row
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Category',
                  style: style,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Total Amount',
                  style: style,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
          // Data rows
          ...categoryEntries
              .map(
                (entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(entry.key, textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${entry.value.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          // Total row
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'Total',
                  style: style.copyWith(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${overallTotal.toStringAsFixed(2)}',
                  style: style.copyWith(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // In the _buildAllEntriesContent method
  List<pw.Widget> _buildAllEntriesContent(
    List<CashFlowTransaction> transactions,
    pw.TextStyle style,
    pw.TextStyle contentStyle,
    String reportType,
  ) {
    // Conditionally include/exclude employee column
    final bool showEmployee = reportType.toLowerCase() != 'expense';

    // Calculate totals
    double totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    double totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    double totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Create a smaller text style for table content
    final tableContentStyle = contentStyle.copyWith(fontSize: 8);
    final tableHeaderStyle = style.copyWith(fontSize: 10);

    return [
      // Transactions Table
      pw.Table.fromTextArray(
        headerStyle: tableHeaderStyle,
        cellStyle: tableContentStyle,
        headers: [
          'Date',
          'Description',
          'Category',
          if (showEmployee) 'Employee',
          'Amount',
        ],
        data:
            transactions.map((t) {
              final baseData = [
                DateFormat.yMd().format(t.date),
                t.description ?? 'No description',
                t.category,
                if (showEmployee) t.employeeName ?? 'N/A',
                '${t.amount.toStringAsFixed(0)}',
              ];
              return baseData;
            }).toList(),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
        },
      ),

      pw.SizedBox(height: 10), // Reduced from 20
      // Summary Table
      pw.Table(
        border: pw.TableBorder.all(
          color: PdfColors.black,
          width: 0.5,
        ), // Thinner border
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
        children: [
          // Total row
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4), // Reduced padding
                child: pw.Text(
                  textAlign: pw.TextAlign.center,
                  'Total',
                  style: tableHeaderStyle.copyWith(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8.5, // Smaller font
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4), // Reduced padding
                child: pw.Text(
                  '${totalAmount.toStringAsFixed(0)}',
                  style: tableHeaderStyle.copyWith(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
          // Additional rows for All report type
          if (reportType == 'All') ...[
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4), // Reduced padding
                  child: pw.Text(
                    'Total Income',
                    style: tableContentStyle.copyWith(color: PdfColors.green),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4), // Reduced padding
                  child: pw.Text(
                    '${totalIncome.toStringAsFixed(0)}',
                    style: tableContentStyle.copyWith(color: PdfColors.green),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4), // Reduced padding
                  child: pw.Text(
                    'Total Expenses',
                    style: tableContentStyle.copyWith(color: PdfColors.red),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4), // Reduced padding
                  child: pw.Text(
                    '${totalExpenses.toStringAsFixed(0)}',
                    style: tableContentStyle.copyWith(color: PdfColors.red),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4), // Reduced padding
                  child: pw.Text(
                    'Net Cash Flow',
                    style: tableContentStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      color:
                          (totalIncome - totalExpenses) >= 0
                              ? PdfColors.green
                              : PdfColors.red,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4), // Reduced padding
                  child: pw.Text(
                    '${(totalIncome - totalExpenses).toStringAsFixed(0)}',
                    style: tableContentStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      color:
                          (totalIncome - totalExpenses) >= 0
                              ? PdfColors.green
                              : PdfColors.red,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ];
  }

  // static pw.Widget _buildSignatureSection() {
  //   return pw.Align(
  //     alignment: pw.Alignment.bottomRight,
  //     child: pw.Column(
  //       mainAxisAlignment: pw.MainAxisAlignment.end,
  //       // mainAxisSize: pw.MainAxisSize.min,
  //       children: [
  //         pw.Container(
  //           alignment: pw.Alignment.bottomRight,
  //           width: 150,
  //           height: 1,
  //           color: PdfColors.black,
  //         ),
  //         pw.SizedBox(height: 5),
  //         pw.Text(
  //           'Authorized Signature',
  //           style: pw.TextStyle(
  //             fontSize: 10,
  //             fontStyle: pw.FontStyle.italic,
  //             fontWeight: pw.FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // NEW HELPER METHOD FOR TIME RANGE OPTIONS
  Widget _buildTimeRangeOption(
    BuildContext context,
    String reportType,
    String timeframe,
  ) {
    return ListTile(
      title: Text(timeframe),
      onTap: () async {
        Navigator.pop(context); // Close the initial dialog

        if (timeframe == 'Custom Range') {
          // Store the context in a variable before async operation
          final currentContext = this.context;

          final DateTimeRange? selectedRange = await _selectCustomDateRange(
            currentContext,
            reportType,
          );

          // Check if the widget is still mounted before proceeding
          if (mounted && selectedRange != null) {
            if (reportType == 'Net Cash Flow') {
              _generatePdf(
                reportType,
                'custom',
                dateRange: selectedRange,
                reportFormat: 'all',
              );
            } else {
              _showReportFormatDialog(
                currentContext,
                reportType,
                'custom',
                dateRange: selectedRange,
              );
            }
          }
        } else {
          // Handle other time ranges as before
          if (reportType == 'Net Cash Flow') {
            _generatePdf(
              reportType,
              timeframe.toLowerCase().replaceAll(' ', '_'),
              dateRange: null,
              reportFormat: 'all',
            );
          } else {
            _showReportFormatDialog(
              context,
              reportType,
              timeframe.toLowerCase().replaceAll(' ', '_'),
            );
          }
        }
      },
    );
  }

  String _getDateRangeText(String timeframe, DateTimeRange? dateRange) {
    final now = DateTime.now();

    switch (timeframe) {
      case 'today':
        return DateFormat.yMd().format(now);
      case 'yesterday':
        return DateFormat.yMd().format(now.subtract(Duration(days: 1)));
      case 'this_week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(now)}';
      case 'last_week':
        final start = now.subtract(Duration(days: now.weekday + 6));
        final end = start.add(Duration(days: 6));
        return '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(end)}';
      case 'this_month':
        final start = DateTime(now.year, now.month, 1);
        return '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(now)}';
      case 'last_month':
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayLastMonth = DateTime(now.year, now.month, 0);
        return '${DateFormat.MMMd().format(firstDayLastMonth)} - ${DateFormat.MMMd().format(lastDayLastMonth)}';

      case 'custom':
        return '${DateFormat.yMd().format(dateRange!.start)} - ${DateFormat.yMd().format(dateRange.end)}';
      default:
        return 'All Time';
    }
  }
}
