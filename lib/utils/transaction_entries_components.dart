import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/views.dart';

// Common gradient background used in multiple screens
Widget buildGradientBackground({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color.fromARGB(255, 37, 73, 136),
          const Color.fromARGB(172, 103, 52, 8),
          Color.fromRGBO(234, 206, 280, 1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: child,
  );
}

// Reusable search bar widget
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search by description',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: hintText,
          labelStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white70),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}

// Reusable detail row for transaction details
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double fontSize;

  const DetailRow({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor = Colors.black87,
    this.fontSize = 11,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize.sp,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize.sp,
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Base transaction tile that can be customized for different transaction types
class BaseTransactionTile extends StatelessWidget {
  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final Color titleColor;
  final List<Widget> subtitleChildren;
  final VoidCallback onTap;
  final Widget? trailing;

  const BaseTransactionTile({
    Key? key,
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.titleColor,
    required this.subtitleChildren,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ListTile(
        onTap: onTap,
        leading: Icon(leadingIcon, color: leadingColor, size: 15.sp),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subtitleChildren,
        ),
        trailing:
            trailing ??
            Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
      ),
    );
  }
}

// Specific implementation for Cash Flow transactions
class CashFlowTransactionTile extends StatelessWidget {
  final CashFlowTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CashFlowTransactionTile({
    Key? key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if transaction is employee-related
    final isEmployeeTransaction =
        transaction.category.toLowerCase() == 'commission' ||
        transaction.category.toLowerCase() == 'advance' ||
        transaction.category.toLowerCase() == 'full_salary';

    final investorProfit =
        transaction.category.toLowerCase() == 'investor profit';

    return BaseTransactionTile(
      leadingIcon:
          transaction.commission != null && transaction.commission! > 0
              ? Icons.compare_arrows_sharp
              : (transaction.type == 'income'
                  ? Icons.arrow_circle_up
                  : Icons.arrow_circle_down),
      leadingColor: transaction.type == 'income' ? Colors.green : Colors.red,
      title: '${transaction.amount.toStringAsFixed(1)}',
      titleColor: transaction.type == 'income' ? Colors.green : Colors.red,
      onTap: onTap,
      // Only show popup menu if NOT an employee transaction
      trailing:
          isEmployeeTransaction || investorProfit
              ? null // No trailing widget for employee transactions
              : PopupMenuButton(
                itemBuilder:
                    (context) => [
                      PopupMenuItem(child: Text('Delete'), onTap: onDelete),
                      PopupMenuItem(child: Text('Edit'), onTap: onEdit),
                    ],
              ),
      subtitleChildren: [
        Text(
          transaction.category == 'full_salary'
              ? 'Staff Salary'
              : transaction.category,
          style: TextStyle(fontSize: 11.sp),
        ),
        if (transaction.description.isNotEmpty) SizedBox(height: 4.sp),
        if (transaction.description.isNotEmpty)
          Text(
            transaction.description,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: 4.sp),
        Text(
          _formatDate(transaction.date),
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
        SizedBox(height: 4.sp),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

// Specific implementation for Wallet transactions
class WalletTransactionTile extends StatelessWidget {
  final WalletTransaction transaction;
  final VoidCallback onTap;

  const WalletTransactionTile({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseTransactionTile(
      leadingIcon:
          transaction.type == 'credit' ? Icons.add_circle : Icons.remove_circle,
      leadingColor: transaction.type == 'credit' ? Colors.green : Colors.red,
      title: '${transaction.amount.toStringAsFixed(1)}',
      titleColor: transaction.type == 'credit' ? Colors.green : Colors.red,
      onTap: onTap,
      subtitleChildren: [
        Text(
          transaction.type.toUpperCase(),
          style: TextStyle(
            fontSize: 11.sp,
            color: transaction.type == 'credit' ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.sp),
        if (transaction.description.isNotEmpty) SizedBox(height: 4.sp),
        if (transaction.description.isNotEmpty)
          Text(
            transaction.description,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: 4.sp),
        Text(
          _formatDate(transaction.createdAt),
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
        SizedBox(height: 4.sp),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

// Reusable balance card widget
class BalanceCard extends StatelessWidget {
  final String title;
  final double balance;
  final Color balanceColor;

  const BalanceCard({
    Key? key,
    required this.title,
    required this.balance,
    this.balanceColor = Colors.green,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${balance.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable transaction details dialog
class TransactionDetailsDialog extends StatelessWidget {
  final String title;
  final List<DetailRow> details;

  const TransactionDetailsDialog({
    Key? key,
    required this.title,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

// Date formatting utilities
class DateFormatters {
  static String formatFullDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTimeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

// Common refresh functionality mixin
mixin RefreshableScreen<T extends StatefulWidget> on State<T> {
  Future<void> refreshData(Future<void> Function() refreshFunction) async {
    final loadingProvider = context.read<LoadingProvider>();

    try {
      loadingProvider.startLoading();
      await refreshFunction();
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error Fetching Data',
      );
    } finally {
      loadingProvider.stopLoading();
    }
  }
}

// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? searchQuery;

  const EmptyStateWidget({Key? key, required this.message, this.searchQuery})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        searchQuery?.isEmpty ?? true
            ? message
            : 'No results for "$searchQuery"',
        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
      ),
    );
  }
}
