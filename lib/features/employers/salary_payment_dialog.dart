import 'package:flutter/material.dart';
import 'package:rmn_accounts/utils/views.dart';
import 'package:sizer/sizer.dart';

class SalaryPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Map<String, dynamic> categories;

  const SalaryPaymentDialog({
    super.key,
    required this.employee,
    required this.categories,
  });

  @override
  State<SalaryPaymentDialog> createState() => _SalaryPaymentDialogState();
}

class _SalaryPaymentDialogState extends State<SalaryPaymentDialog> {
  final _amountController = TextEditingController();
  String _selectedType = 'salary';
  double _maxAmount = 0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _maxAmount = widget.employee['unpaid_salary'];
    _selectedType = _maxAmount > 0 ? 'salary' : 'advance';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Process Salary Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentTypeSelector(),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                suffix: TextButton(
                  child: Text('Max'),
                  onPressed:
                      () =>
                          _amountController.text = _maxAmount.toStringAsFixed(
                            2,
                          ),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            _buildBalanceInfo(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateInput ? _submitPayment : null,
          child: Text('Confirm Payment'),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: [
        if (widget.employee['unpaid_salary'] > 0)
          DropdownMenuItem(value: 'salary', child: Text('Regular Salary')),
        DropdownMenuItem(value: 'commission', child: Text('Add Commission')),
        DropdownMenuItem(value: 'advance', child: Text('Salary Advance')),
      ],
      onChanged:
          (value) => setState(() {
            _selectedType = value!;
            _updateMaxAmount();
          }),
      decoration: InputDecoration(
        labelText: 'Payment Type',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Current Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          widget.employee['unpaid_salary'].toStringAsFixed(2),
          style: TextStyle(
            color: _getBalanceColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getBalanceColor() {
    final balance = widget.employee['unpaid_salary'];
    return balance < 0
        ? Colors.amber.shade800
        : balance > 0
        ? Colors.red
        : Colors.green;
  }

  void _updateMaxAmount() {
    switch (_selectedType) {
      case 'advance':
        _maxAmount = widget.employee['salary'] * 0.5;
        break;
      case 'commission':
        _maxAmount = double.infinity;
        break;
      default:
        _maxAmount = widget.employee['unpaid_salary'];
    }
    if (_amountController.text.isNotEmpty) {
      _amountController.text = _maxAmount.toStringAsFixed(2);
    }
  }

  bool get _validateInput {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;
    if (_selectedType == 'advance' && amount > _maxAmount) return false;
    return true;
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      final employeeCheck = await _supabase
          .from('employers')
          .select()
          .eq('employee_id', widget.employee['employee_id']);

      if (employeeCheck.isEmpty) {
        throw Exception('Employee no longer exists in the system');
      }

      // Proceed with payment
      // Navigator.pop(context, _buildPaymentResult());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
