import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/features/auth/presentation/view_Model/cashflow_transaction_model.dart';
import 'package:rmn_accounts/utils/views.dart';

class TransactionForm extends StatefulWidget {
  final CashFlowTransaction? transaction;

  const TransactionForm({Key? key, this.transaction}) : super(key: key);

  @override
  TransactionFormState createState() => TransactionFormState();
}

class TransactionFormState extends State<TransactionForm> {
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  late final TextEditingController employeeIdController;
  late final TextEditingController commissionController;
  late final GlobalKey<FormState> formKey;
  bool _isEditing = false;
  late DateTime _selectedDate;
  late bool _showEmployeeFields;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    descriptionController = TextEditingController();
    employeeIdController = TextEditingController();
    commissionController = TextEditingController();
    formKey = GlobalKey<FormState>();

    _selectedDate = widget.transaction?.date ?? DateTime.now();

    // FIXED: Better initialization for employee fields
    _showEmployeeFields =
        widget.transaction?.employeeId != null &&
        widget.transaction?.employeeId!.isNotEmpty == true;

    // Reset provider state
    final provider = Provider.of<CashFlowProvider>(context, listen: false);
    provider.resetFormState();

    // Initialize form if editing existing transaction
    if (widget.transaction != null) {
      _isEditing = true;
      final t = widget.transaction!;
      amountController.text = t.amount.toString();
      descriptionController.text = t.description;

      // FIXED: Initialize employee fields properly
      if (t.employeeId != null && t.employeeId!.isNotEmpty) {
        employeeIdController.text = t.employeeId!;
        commissionController.text = t.commission?.toString() ?? '';

        // Also update provider's employee verification
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.verifyEmployee(t.employeeId!); // Verify employee
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    employeeIdController.dispose();
    commissionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blueGrey[50]!, Colors.blueGrey[100]!],
            ),
          ),
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: formKey,
            child: Consumer<CashFlowProvider>(
              builder: (context, provider, _) {
                // Set initial values for provider state when editing
                if (_isEditing) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    provider
                      ..setSelectedType(widget.transaction!.type)
                      ..setSelectedCategory(widget.transaction!.category);
                  });
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isEditing ? 'Edit Transaction' : 'Add Transaction',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    ToggleButtons(
                      isSelected: [
                        provider.selectedType == 'income',
                        provider.selectedType == 'expense',
                      ],
                      onPressed: (index) {
                        provider.setSelectedType(
                          index == 0 ? 'income' : 'expense',
                        );
                      },
                      borderRadius: BorderRadius.circular(8.sp),
                      selectedColor: Colors.white,
                      fillColor: Colors.blueAccent,
                      color: Colors.blueGrey[800],
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text('Income'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text('Expense'),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    DropdownButtonFormField<String>(
                      value: provider.selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Select Category'),
                        ),
                        ...(provider.selectedType == 'income'
                                ? provider.incomeCategories
                                : provider.expenseCategories)
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: provider.setSelectedCategory,
                      validator:
                          (value) =>
                              value == null ? 'Please select a category' : null,
                    ),
                    SizedBox(height: 2.h),
                    CustomTextFormField(
                      controller: amountController,
                      labelText: 'Amount',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter amount';
                        if (double.tryParse(value!) == null)
                          return 'Invalid amount';
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    CustomTextFormField(
                      controller: descriptionController,
                      labelText: 'Description',
                      prefixIcon: Icons.description,
                      maxLines: 2,
                    ),
                    SizedBox(height: 2.h),
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: Colors.blueGrey[800],
                      ),
                      title: Text(
                        'Transaction Date',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.all(8.sp),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade400,
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        child: Text(
                          'Change Date',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      onTap: () => _selectDate(context),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                        side: BorderSide(color: Colors.blueGrey[300]!),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (provider.selectedType == 'income')
                      CheckboxListTile(
                        title: Text('Is this employee commission?'),
                        value: _showEmployeeFields,
                        onChanged: (value) {
                          setState(() {
                            _showEmployeeFields = value ?? false;

                            // FIXED: Clear fields when unchecked
                            if (!_showEmployeeFields) {
                              employeeIdController.clear();
                              commissionController.clear();
                              provider
                                  .clearSelectedEmployee(); // Add this method to your provider
                            }
                          });
                        },
                      ),

                    // FIXED: Updated logic for employee fields
                    if (_showEmployeeFields &&
                        provider.selectedType == 'income') ...[
                      SizedBox(height: 2.h),
                      CustomTextFormField(
                        controller: employeeIdController,
                        labelText: 'Employee ID',
                        prefixIcon: Icons.person,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () async {
                            if (employeeIdController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter Employee ID'),
                                ),
                              );
                              return;
                            }
                            try {
                              await provider.verifyEmployee(
                                employeeIdController.text,
                              );
                              if (provider.selectedEmployee == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Employee not found')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        ),
                        validator: (value) {
                          if (_showEmployeeFields && (value?.isEmpty ?? true)) {
                            return 'Please enter employee ID';
                          }
                          return null;
                        },
                      ),
                      if (provider.selectedEmployee != null) ...[
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.all(8.sp),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8.sp),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  'Employee: ${provider.selectedEmployee}',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),
                      CustomTextFormField(
                        controller: commissionController,
                        labelText: 'Employee Commission',
                        prefixIcon: Icons.money,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (_showEmployeeFields && (value?.isEmpty ?? true))
                            return 'Please enter commission';
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null)
                            return 'Invalid amount';
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 3.h),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          // FIXED: Proper validation for employee fields
                          if (_showEmployeeFields) {
                            if (employeeIdController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter Employee ID'),
                                ),
                              );
                              return;
                            }
                            if (provider.selectedEmployee == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please verify employee ID first',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (commissionController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter commission amount',
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          final loadingProvider =
                              context.read<LoadingProvider>();
                          try {
                            loadingProvider.startLoading();

                            // FIXED: Prepare employee data properly
                            String? employeeId;
                            int? commission;

                            if (_showEmployeeFields) {
                              employeeId = employeeIdController.text;
                              commission = int.tryParse(
                                commissionController.text,
                              );
                            }

                            if (_isEditing) {
                              // UPDATE EXISTING TRANSACTION
                              await provider.updateTransaction(
                                id: widget.transaction!.id,
                                amount: double.parse(amountController.text),
                                description: descriptionController.text,
                                employeeId: employeeId,
                                commission: commission,
                                incentives:
                                    commission, // Are incentives same as commission?
                                date: _selectedDate,
                              );
                            } else {
                              await provider.submitTransaction(
                                amount: double.parse(amountController.text),
                                description: descriptionController.text,
                                employeeId: employeeId,
                                commission: commission,
                                incentives:
                                    commission, // Are incentives same as commission?
                                date: _selectedDate,
                              );
                            }

                            // Clear all form fields
                            amountController.clear();
                            descriptionController.clear();
                            employeeIdController.clear();
                            commissionController.clear();

                            // Reset form state
                            provider.setSelectedCategory(null);
                            setState(() {
                              _showEmployeeFields = false;
                            });

                            Navigator.pop(context);
                            SupabaseExceptionHandler.showSuccessSnackbar(
                              context,
                              _isEditing
                                  ? 'Transaction updated successfully'
                                  : 'Transaction added successfully',
                            );
                          } catch (e) {
                            SupabaseExceptionHandler.showErrorSnackbar(
                              context,
                              'Error: $e',
                            );
                            print('Transaction error: $e');
                          } finally {
                            loadingProvider.stopLoading();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: Size(double.infinity, 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update' : 'Submit',
                        style: TextStyle(fontSize: 12.sp, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 1.h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
