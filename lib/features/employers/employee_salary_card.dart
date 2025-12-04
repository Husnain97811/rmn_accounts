import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmployeeSalaryCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onPayPressed;
  final VoidCallback onStatementPressed;

  const EmployeeSalaryCard({
    super.key,
    required this.employee,
    required this.onPayPressed,
    required this.onStatementPressed,
  });

  @override
  Widget build(BuildContext context) {
    final unpaid = employee['unpaid_salary'] as double;
    final isPaid = employee['is_salary_paid'] as bool;

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(1.5.h),
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  employee['name'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, size: 15.sp),
                  onPressed: onStatementPressed,
                ),
              ],
            ),
            Divider(),
            _buildSalaryRow('Basic Salary', employee['salary']),
            _buildSalaryRow('Commission', employee['commission']),
            _buildSalaryRow('Paid', employee['paid_salary']),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: _getStatusColor(isPaid, unpaid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance: ${unpaid.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getTextColor(isPaid, unpaid),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onPayPressed,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                    ),
                    child: Text('Pay', style: TextStyle(fontSize: 10.sp)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10.sp)),
          Text(
            value?.toStringAsFixed(2) ?? '0.00',
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isPaid, double unpaid) {
    if (unpaid < 0) return Colors.amber.withOpacity(0.2);
    return isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2);
  }

  Color _getTextColor(bool isPaid, double unpaid) {
    if (unpaid < 0) return Colors.amber.shade800;
    return isPaid ? Colors.green.shade800 : Colors.red.shade800;
  }
}
