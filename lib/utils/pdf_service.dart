import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'views.dart';

class PdfService {
  // Common PDF styles
  static final _titleStyle = pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 18.8,
    color: PdfColors.black,
  );

  static final _subtitleStyle = pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 13.8,
    color: PdfColors.black,
  );

  static final _contentStyle = pw.TextStyle(
    fontSize: 9,
    color: PdfColors.black,
  );

  static final _headerStyle = pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 11,
    color: PdfColors.black,
  );

  // Generate Cash Flow Report
  static Future<File> generateCashFlowReport({
    required String reportType,
    required String timeframe,
    required List<CashFlowTransaction> transactions,
    DateTimeRange? dateRange,
    required String reportFormat,
  }) async {
    final pdf = pw.Document();
    final primaryColor = PdfColors.blueGrey800;

    // Sort transactions in ascending order (oldest first)
    transactions.sort((a, b) => a.date.compareTo(b.date));

    double totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    double totalExpenses = transactions
        .where((t) => t.type == 'expense') // Only regular expenses
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate commission from income transactions
    // double commissionExpenses = transactions
    //     .where(
    //       (t) =>
    //           t.type == 'income' &&
    //           t.commission != null &&
    //           t.commission! > 0 &&
    //           (t.employeeId != null && t.employeeId!.isNotEmpty),
    //     )
    //     .fold(0.0, (sum, t) => sum + (t.commission ?? 0));

    // double totalExpenses = regularExpenses + commissionExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              children: [
                pw.Text(
                  'Reliable Marketing Network Pvt Ltd',
                  style: _titleStyle,
                ),
                pw.SizedBox(height: 4),
                pw.Text('$reportType Report', style: _subtitleStyle),
                // if (commissionExpenses > 0 && reportType == 'Expense')
                //   pw.Text(
                //     '(Includes ${commissionExpenses.toStringAsFixed(2)} in Employee Commissions)',
                //     style: pw.TextStyle(fontSize: 10, color: PdfColors.red),
                //   ),
                pw.Divider(color: primaryColor),
                pw.SizedBox(height: 34),
              ],
            );
          }
          return pw.SizedBox.shrink();
        },
        build: (context) {
          return [
            if (reportType == 'Net Cash Flow') ...[
              _buildNetSummary(totalIncome, totalExpenses),
              pw.SizedBox(height: 20),
              _buildComparisonChart(totalIncome, totalExpenses),
              pw.SizedBox(height: 20),
              _buildPercentageBreakdown(totalIncome, totalExpenses),
              pw.SizedBox(height: 20),
              _buildNetResult(totalIncome, totalExpenses),
              pw.SizedBox(height: 40),
            ] else if (reportFormat == 'category')
              ..._buildCategoryWiseContent(transactions, _headerStyle)
            else
              ..._buildAllEntriesContent(
                transactions,
                _headerStyle,
                _contentStyle,
                reportType,
                // includeCommissionAsExpense: reportType == 'Expense',
              ),
          ];
        },
        footer:
            (pw.Context context) => _buildSignatureSection(
              timeframe: timeframe,
              dateRange: dateRange,
            ),
      ),
    );

    final directory = await getDownloadsDirectory();
    final file = File(
      '${directory!.path}/${reportType}_${reportFormat}_${DateTime.now().millisecondsSinceEpoch}_report.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Generate Wallet Transactions Report with time filter
  static Future<File> generateWalletReport({
    required List<WalletTransaction> transactions,
    required double currentBalance,
    String timeframe = 'all',
    DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();

    // Filter transactions based on timeframe
    List<WalletTransaction> filteredTransactions = _filterWalletTransactions(
      transactions,
      timeframe,
      dateRange,
    );

    // Sort wallet transactions in ascending order (oldest first)
    filteredTransactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Calculate totals for filtered period
    double totalCredit = filteredTransactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);

    double totalDebit = filteredTransactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);

    double netChange = totalCredit - totalDebit;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Reliable Marketing Network Pvt Ltd',
                style: _titleStyle,
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Wallet Transactions Report',
                style: _subtitleStyle,
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(color: PdfColors.blueGrey800),
              pw.SizedBox(height: 34),
            ],
          );
        },
        build: (context) {
          return [
            // Current balance
            pw.Text(
              'Current Wallet Balance: ${currentBalance.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),

            // Summary for selected period
            if (timeframe != 'all')
              pw.Column(
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Period Summary',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  _buildWalletSummaryCard(totalCredit, totalDebit, netChange),
                  pw.SizedBox(height: 20),
                ],
              ),

            // Transactions table
            pw.SizedBox(height: 10),
            _buildWalletTransactionsTable(filteredTransactions),
          ];
        },
        footer:
            (pw.Context context) => _buildSignatureSection(
              timeframe: timeframe == 'all' ? null : timeframe,
              dateRange: dateRange,
            ),
      ),
    );

    final directory = await getDownloadsDirectory();
    final fileName =
        timeframe == 'all'
            ? 'wallet_transactions_all_${DateTime.now().millisecondsSinceEpoch}.pdf'
            : 'wallet_transactions_${timeframe}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final file = File('${directory!.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Filter wallet transactions based on timeframe
  static List<WalletTransaction> _filterWalletTransactions(
    List<WalletTransaction> transactions,
    String timeframe,
    DateTimeRange? dateRange,
  ) {
    if (timeframe == 'all') return transactions;

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (timeframe) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'yesterday':
        final yesterday = now.subtract(Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        break;
      case 'this_week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        endDate = now;
        break;
      case 'last_week':
        final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
        final endOfLastWeek = startOfLastWeek.add(Duration(days: 6));
        startDate = DateTime(
          startOfLastWeek.year,
          startOfLastWeek.month,
          startOfLastWeek.day,
        );
        endDate = DateTime(
          endOfLastWeek.year,
          endOfLastWeek.month,
          endOfLastWeek.day,
          23,
          59,
          59,
        );
        break;
      case 'this_month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'last_month':
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayLastMonth = DateTime(now.year, now.month, 0);
        startDate = firstDayLastMonth;
        endDate = DateTime(
          lastDayLastMonth.year,
          lastDayLastMonth.month,
          lastDayLastMonth.day,
          23,
          59,
          59,
        );
        break;
      case 'custom':
        if (dateRange != null) {
          startDate = dateRange.start;
          endDate = dateRange.end;
        } else {
          return transactions; // Fallback to all if no dateRange provided
        }
        break;
      default:
        return transactions;
    }

    return transactions.where((transaction) {
      return transaction.createdAt.isAfter(
            startDate.subtract(Duration(seconds: 1)),
          ) &&
          transaction.createdAt.isBefore(endDate.add(Duration(seconds: 1)));
    }).toList();
  }

  // Wallet Summary Card for selected period
  static pw.Widget _buildWalletSummaryCard(
    double totalCredit,
    double totalDebit,
    double netChange,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildPdfSummaryCard('Total Credit', totalCredit, PdfColors.green),
        _buildPdfSummaryCard('Total Debit', totalDebit, PdfColors.red),
        _buildPdfSummaryCard(
          'Net Change',
          netChange,
          netChange >= 0 ? PdfColors.green : PdfColors.red,
        ),
      ],
    );
  }

  // Wallet Transactions Table
  static pw.Widget _buildWalletTransactionsTable(
    List<WalletTransaction> transactions,
  ) {
    // Define the styles for table headers and content
    final tableHeaderStyle = _headerStyle.copyWith(fontSize: 10);
    final tableContentStyle = _contentStyle.copyWith(fontSize: 8);

    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: tableHeaderStyle,
      cellStyle: tableContentStyle,
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(5),
        3: const pw.FlexColumnWidth(3),
      },
      headers: ['Date', 'Type', 'Description', 'Amount'],
      data:
          transactions.map((transaction) {
            return [
              DateFormat('yyyy-MM-dd').format(transaction.createdAt),
              transaction.type.toUpperCase(),
              transaction.description,
              pw.Text(
                '${transaction.amount.toStringAsFixed(0)}',
                style: tableContentStyle.copyWith(
                  color:
                      transaction.type == 'credit'
                          ? PdfColors.green
                          : PdfColors.red,
                ),
              ),
            ];
          }).toList(),
    );
  }

  // Show time selection dialog for wallet reports
  static void showWalletTimeSelectionDialog(
    BuildContext context, {
    required Function(String, DateTimeRange?) onTimeSelected,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Report Period'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    [
                          _buildTimeRangeOption('All Time', 'all', null),
                          _buildTimeRangeOption('Today', 'today', null),
                          _buildTimeRangeOption('Yesterday', 'yesterday', null),
                          _buildTimeRangeOption('This Week', 'this_week', null),
                          _buildTimeRangeOption('Last Week', 'last_week', null),
                          _buildTimeRangeOption(
                            'This Month',
                            'this_month',
                            null,
                          ),
                          _buildTimeRangeOption(
                            'Last Month',
                            'last_month',
                            null,
                          ),
                          _buildTimeRangeOption('Custom Range', 'custom', null),
                        ]
                        .map(
                          (option) => ListTile(
                            title: Text(option.$1),
                            onTap: () async {
                              Navigator.pop(context);

                              if (option.$1 == 'Custom Range') {
                                final DateTimeRange? selectedRange =
                                    await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                      initialDateRange: DateTimeRange(
                                        start: DateTime.now().subtract(
                                          Duration(days: 7),
                                        ),
                                        end: DateTime.now(),
                                      ),
                                    );

                                if (selectedRange != null) {
                                  onTimeSelected(option.$2, selectedRange);
                                }
                              } else {
                                onTimeSelected(option.$2, null);
                              }
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
    );
  }

  // Helper method to create time range options
  static (String, String, DateTimeRange?) _buildTimeRangeOption(
    String label,
    String value,
    DateTimeRange? dateRange,
  ) {
    return (label, value, dateRange);
  }

  // ================== COMMON PDF COMPONENTS ================== //

  static pw.Widget _buildNetSummary(
    double totalIncome,
    double totalExpenses,
    // Remove commissionExpenses parameter since we're not using it
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Financial Summary',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total Income:', style: _contentStyle),
                pw.Text('Total Expenses:', style: _contentStyle),
                pw.Text(
                  'Net Cash Flow:',
                  style: _contentStyle.copyWith(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${totalIncome.toStringAsFixed(2)}',
                  style: _contentStyle.copyWith(color: PdfColors.green),
                ),
                pw.Text(
                  '${totalExpenses.toStringAsFixed(2)}',
                  style: _contentStyle.copyWith(color: PdfColors.red),
                ),
                pw.Text(
                  '${(totalIncome - totalExpenses).toStringAsFixed(2)}',
                  style: _contentStyle.copyWith(
                    color:
                        (totalIncome - totalExpenses) >= 0
                            ? PdfColors.green
                            : PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPdfSummaryCard(
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
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

  static pw.Widget _buildCommissionBreakdown(
    List<CashFlowTransaction> transactions,
  ) {
    final commissionTransactions =
        transactions
            .where(
              (t) =>
                  t.type == 'income' &&
                  t.commission != null &&
                  t.commission! > 0 &&
                  (t.employeeId != null && t.employeeId!.isNotEmpty),
            )
            .toList();

    if (commissionTransactions.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Employee Commission Breakdown:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Date', style: _headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Employee', style: _headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Income Amount', style: _headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Commission', style: _headerStyle),
                ),
              ],
            ),
            ...commissionTransactions.map((transaction) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      DateFormat('dd/MM/yyyy').format(transaction.date),
                      style: _contentStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      transaction.employeeName ?? 'N/A',
                      style: _contentStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      transaction.amount.toStringAsFixed(2),
                      style: _contentStyle.copyWith(color: PdfColors.green),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      (transaction.commission ?? 0).toStringAsFixed(2),
                      style: _contentStyle,
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildComparisonChart(double income, double expenses) {
    final maxValue = income > expenses ? income : expenses;
    return pw.Container(
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
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
            border: pw.Border.all(color: PdfColors.black),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: (incomePercent / 100) * 200,
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
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Expenses: ${expensePercent.toStringAsFixed(1)}%',
              style: pw.TextStyle(fontSize: 12),
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
        border: pw.Border.all(color: PdfColors.black),
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

  static pw.Widget _buildSignatureSection({
    String? timeframe,
    DateTimeRange? dateRange,
  }) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildSignatureLine(),
          pw.SizedBox(height: 24),
          if (timeframe != null && timeframe != 'all')
            pw.Text(
              'Period: ${_getDateRangeText(timeframe, dateRange)}',
              style: pw.TextStyle(fontSize: 8),
            ),
          pw.Text(
            'Generated on ${DateFormat.yMd().format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine() {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.end,
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
    );
  }

  static String _getDateRangeText(String timeframe, DateTimeRange? dateRange) {
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

  static List<pw.Widget> _buildCategoryWiseContent(
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

    final categoryEntries = categoryTotals.entries.toList();

    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 1),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
        children: [
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

  static List<pw.Widget> _buildAllEntriesContent(
    List<CashFlowTransaction> transactions,
    pw.TextStyle headerStyle,
    pw.TextStyle contentStyle,
    String reportType,
  ) {
    // Create a list to hold all entries
    List<CashFlowTransaction> allEntries = [];

    if (reportType == 'Income') {
      // For Income report: Only show income transactions
      allEntries = transactions.where((t) => t.type == 'income').toList();
    } else if (reportType == 'Expense') {
      // For Expense report: ONLY show regular expenses, NOT commissions
      allEntries = transactions.where((t) => t.type == 'expense').toList();
      // Remove commission logic entirely
    } else if (reportType == 'Net Cash Flow' || reportType == 'all') {
      // For Net Cash Flow or All: Show all transactions as they are
      allEntries = List.from(transactions);
    }

    // If no entries, show a message
    if (allEntries.isEmpty) {
      return [
        pw.Center(
          child: pw.Text(
            'No transactions found for $reportType report',
            style: contentStyle,
          ),
        ),
      ];
    }

    // Sort all entries by date (ascending)
    allEntries.sort((a, b) => a.date.compareTo(b.date));

    // Calculate totals - DON'T include commissions
    double totalAmount = allEntries.fold(0.0, (sum, t) => sum + t.amount);

    // Build the table - REMOVE commission-related logic
    List<pw.TableRow> tableRows = [];

    // Table header
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Date',
              style: headerStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Type',
              style: headerStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Category',
              style: headerStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Amount',
              style: headerStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'Description',
              style: headerStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    // Add regular transactions
    for (var transaction in allEntries) {
      tableRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                DateFormat('dd/MM/yyyy').format(transaction.date),
                style: contentStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                transaction.type,
                style: contentStyle.copyWith(),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                transaction.category,
                style: contentStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${transaction.amount.toStringAsFixed(2)}',
                style: contentStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                transaction.description,
                style: contentStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return [
      pw.Text(
        '$reportType Report',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        'Total Entries: ${allEntries.length}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 20),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 1),
        columnWidths: {
          0: pw.FlexColumnWidth(1.0), // Date
          1: pw.FlexColumnWidth(0.8), // Type
          2: pw.FlexColumnWidth(1.0), // Category
          3: pw.FlexColumnWidth(1.0), // Amount
          4: pw.FlexColumnWidth(2.0), // Description
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: tableRows,
      ),
      // Total row
      pw.SizedBox(height: 20),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 1),
        columnWidths: {0: pw.FlexColumnWidth(3.0), 1: pw.FlexColumnWidth(2.5)},
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  'TOTAL',
                  style: headerStyle.copyWith(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  '${totalAmount.toStringAsFixed(2)}',
                  style: headerStyle.copyWith(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static pw.Widget _buildSummaryTable({
    required double totalAmount,
    required double totalIncome,
    required double totalExpenses,
    required String reportType,
    required pw.TextStyle tableHeaderStyle,
    required pw.TextStyle tableContentStyle,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                textAlign: pw.TextAlign.center,
                'Total',
                style: tableHeaderStyle.copyWith(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
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
        if (reportType == 'All')
          ..._buildAdditionalSummaryRows(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            tableContentStyle: tableContentStyle,
          ),
      ],
    );
  }

  static List<pw.TableRow> _buildAdditionalSummaryRows({
    required double totalIncome,
    required double totalExpenses,
    required pw.TextStyle tableContentStyle,
  }) {
    final netCashFlow = totalIncome - totalExpenses;
    return [
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              'Total Income',
              style: tableContentStyle.copyWith(color: PdfColors.green),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
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
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Total Expenses', style: tableContentStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              '${totalExpenses.toStringAsFixed(0)}',
              style: tableContentStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              'Net Cash Flow',
              style: tableContentStyle.copyWith(
                fontWeight: pw.FontWeight.bold,
                color: netCashFlow >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              '${netCashFlow.toStringAsFixed(0)}',
              style: tableContentStyle.copyWith(
                fontWeight: pw.FontWeight.bold,
                color: netCashFlow >= 0 ? PdfColors.green : PdfColors.red,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    ];
  }
}
