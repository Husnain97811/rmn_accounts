import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/views.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _advanceDeductController =
      TextEditingController();
  final TextEditingController _hraController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _conveyanceController = TextEditingController();
  final TextEditingController _incentiveController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();

  // dedeuctions controllers
  final TextEditingController _lateFineController = TextEditingController();
  final TextEditingController _absentFineController = TextEditingController();
  final TextEditingController _loanController = TextEditingController();
  final TextEditingController _medicalInsuranceController =
      TextEditingController();
  final TextEditingController _pfController = TextEditingController();

  Map<String, dynamic>? _selectedEmployee;
  double? _unpaidSalary;
  double? _finalUnpaidSalary;
  double? _unpaidCommission;
  bool _resetAdvance = false;
  double? _currentAdvance;

  static const _companyName = 'Reliable Marketing Network Pvt Ltd';
  static const _companyAddress = '123 Business Street, Financial City, FC 4567';
  static const _companyPhone = '+1 (555) 123-4567';
  static const _companyEmail = 'accounts@rmn.com';

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      //here show inactive employees at bottom on checking status. show hr manager or managers at top
      final response = await _supabase
          .from('employers')
          .select('*')
          // .order('created_at', ascending: false)
          .order('status', ascending: true)
          .order('designation', ascending: true);
      setState(() {
        _employees = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error Fetching Employees\n Check your Connnectivity/ \n OR \n ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_image.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: const Color.fromARGB(202, 255, 255, 255),
            height: 24.sp,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 23.sp),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employees Details',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Pay Salary',
                      icon: Icon(Icons.payment, color: Colors.blue),
                      onPressed: _handleSalaryPayment,
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: Icon(Icons.refresh, color: Colors.blue),
                      onPressed: _fetchEmployees,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 7.h),
                if (_isLoading) SizedBox(height: 7.h),
                if (_isLoading)
                  Center(child: ProviderLoadingWidget())
                else if (_employees.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .signal_cellular_connected_no_internet_4_bar_sharp,
                          color: Colors.red,
                        ),
                        Text(
                          'Error Fetching Employees\n Check your Connectivity',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 1.8.w,
                        mainAxisSpacing: 3.h,
                        childAspectRatio: 1.5, // Width:Height = 1.5:1
                      ),
                      itemCount: _employees.length,
                      itemBuilder: (context, index) {
                        return _buildEmployeeCard(context, _employees[index]);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_employee',
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEmployeeDialog(context),
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    Map<String, dynamic> employee,
  ) {
    final isActive = employee['status'] == 'active';
    final salary = employee['salary']?.toStringAsFixed(0) ?? '0.00';
    final salaryUnPaid = employee['unpaid_salary'] != 0.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.sp),
        onTap: () => _showEmployeeDetails(employee),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: salaryUnPaid ? Colors.orange : Colors.white,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(12.sp),
            color:
                isActive
                    ? Colors.white
                    : const Color.fromARGB(255, 224, 165, 161),
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [Colors.blueGrey[50]!, Colors.blueGrey[100]!],
            // ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.8.sp, vertical: 5.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(0.2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 2.5.w,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage(
                          employee['profile_picture_url'] ??
                              'https://ui-avatars.com/api/?name=${employee['name']}&background=random',
                        ),
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                employee['name'] != null &&
                                        employee['name'].length > 12
                                    ? '${employee['name'].substring(0, 12)}..'
                                    : employee['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize:
                                      employee['name'] != null &&
                                              employee['name'].length <= 10
                                          ? 13.sp
                                          : 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed:
                                        () => _generateDocumentsPdf(employee),
                                    tooltip: 'Generate Documents PDF',
                                    icon: Icon(Icons.document_scanner_outlined),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 15.sp,
                                      color: Colors.black,
                                    ),
                                    onSelected:
                                        (value) => _handleEmployeeAction(
                                          value,
                                          employee,
                                        ),
                                    itemBuilder:
                                        (BuildContext context) => [
                                          const PopupMenuItem<String>(
                                            value: 'Active/Non-Active',
                                            child: Text('Active/Non-Active'),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'update_profile_picture',
                                            child: Text(
                                              'Update Profile Picture',
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'add/update_documents',
                                            child: Text('Add/Update Documents'),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                Row(
                  children: [
                    _buildInfoRow(
                      employee['employee_id'] != null &&
                              employee['employee_id'].isNotEmpty
                          ? Icons.person_2
                          : Icons.person_off,
                      employee['employee_id'].toString().toUpperCase() ??
                          'No Id found',
                      Colors.blueGrey,
                      employee['employee_id'].toString() ?? 'Unknown',
                      employee['status'].toString() == 'active'
                          ? ''
                          : 'Inactive',
                    ),
                  ],
                ),

                // SizedBox(height: 1.h),
                Row(
                  children: [
                    Text(
                      'Designation:',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blueGrey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2.w),

                    Text(
                      employee['designation'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                SizedBox(height: 1.h),

                Row(
                  children: [
                    Text(
                      'Department:',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blueGrey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2.w),

                    Text(
                      employee['department'] == null
                          ? 'N/A'
                          : (employee['department'] != null &&
                                  employee['department'].toString().isNotEmpty
                              ? employee['department']
                                      .toString()[0]
                                      .toUpperCase() +
                                  employee['department']
                                      .toString()
                                      .substring(1)
                                      .toLowerCase()
                              : 'N/A'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open document')));
    }
  }

  // Payment handling methods
  void _handleSalaryPayment() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Payment Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Full Salary'),
                  onTap: () => _showPaymentDialog(paymentType: 'full_salary'),
                ),
                ListTile(
                  title: Text('Commission'),
                  onTap: () => _showPaymentDialog(paymentType: 'commission'),
                ),
                ListTile(
                  title: Text('Advance'),
                  onTap: () => _showPaymentDialog(paymentType: 'advance'),
                ),
              ],
            ),
          ),
    );
  }

  void _showPaymentDialog({required String paymentType}) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              if (paymentType == 'full_salary') {
                _amountController.text =
                    _unpaidSalary?.toStringAsFixed(1) ?? '0.00';
              }

              return AlertDialog(
                title: Text(
                  paymentType == 'commission'
                      ? 'Pay Commission'
                      : paymentType == 'advance'
                      ? 'Give Advance'
                      : 'Pay Full Salary',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          labelText: 'Employee ID',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed:
                                () => _searchEmployee(
                                  _userIdController.text
                                      .toString()
                                      .toLowerCase(),
                                  setState,
                                ),
                          ),
                        ),
                      ),

                      if (_selectedEmployee != null) ...[
                        // here combine unpaid salary and incentives
                        SizedBox(height: 5.sp),
                        Text('Name: ${_selectedEmployee!['name']}'),
                        Text('Unpaid Salary:  $_finalUnpaidSalary'),
                        Text('Unpaid Commission:  $_unpaidCommission'),
                        SizedBox(height: 15.sp),

                        paymentType == 'commission'
                            ? SizedBox.shrink()
                            : Text(
                              'Advance Issued: ${_selectedEmployee!['advance_amount']?.toStringAsFixed(0) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        SizedBox(height: 5.sp),

                        // START OF NEW ADVANCE DEDUCTION UI
                        if (paymentType == 'full_salary') ...[
                          SizedBox(height: 5.sp),

                          // TextFormField(
                          //   controller: _hraController,
                          //   decoration: InputDecoration(
                          //     labelText: 'HRA Amount',
                          //     hintText: 'Enter HRA amount',
                          //   ),
                          //   keyboardType: TextInputType.number,
                          // ),
                          // TextFormField(
                          //   controller: _medicalController,
                          //   decoration: InputDecoration(
                          //     labelText: 'Medical Allowance',
                          //     hintText: 'Enter medical allowance',
                          //   ),
                          //   keyboardType: TextInputType.number,
                          // ),
                          // TextFormField(
                          //   controller: _conveyanceController,
                          //   decoration: InputDecoration(
                          //     labelText: 'Conveyance Allowance',
                          //     hintText: 'Enter conveyance allowance',
                          //   ),
                          //   keyboardType: TextInputType.number,
                          // ),
                          // TextFormField(
                          //   controller: _incentiveController,
                          //   decoration: InputDecoration(
                          //     labelText: 'Incentive Amount',
                          //     hintText: 'Enter incentive amount',
                          //   ),
                          //   keyboardType: TextInputType.number,
                          // ),

                          // ADDED: Commission field for salary payment
                          SizedBox(height: 15.sp),

                          // ADD Commission field if there's unpaid commission
                          if (_unpaidCommission != null &&
                              _unpaidCommission! > 0) ...[
                            TextFormField(
                              controller: _commissionController,
                              decoration: InputDecoration(
                                labelText: 'Commission to Pay',
                                hintText: 'Enter commission amount to pay',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                final amount = double.tryParse(value);
                                if (amount == null) return 'Invalid amount';
                                if (amount > _unpaidCommission!)
                                  return 'Exceeds unpaid commission';
                                return null;
                              },
                            ),
                          ],
                          SizedBox(height: 15.sp),
                          TextFormField(
                            controller: _otherController,
                            decoration: InputDecoration(
                              labelText: 'Bonus',
                              hintText: 'Enter bonus(if any)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 15.sp),
                          Text('Deductions(if any)'),
                          Row(
                            children: [
                              Checkbox(
                                value: _resetAdvance,
                                onChanged: (value) {
                                  setState(() {
                                    _resetAdvance = value!;
                                    if (!_resetAdvance) {
                                      _advanceDeductController.text = '';
                                    }
                                  });
                                },
                              ),
                              Text('Reset Advance'),
                            ],
                          ),
                          if (_resetAdvance)
                            TextFormField(
                              controller: _advanceDeductController,
                              decoration: InputDecoration(
                                labelText: 'Advance to Deduct',
                                hintText: 'Enter amount to deduct',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_resetAdvance &&
                                    (value == null || value.isEmpty)) {
                                  return 'Enter deduction amount';
                                }
                                final amount = double.tryParse(value!);
                                if (amount == null) return 'Invalid amount';
                                if (amount > (_currentAdvance ?? 0)) {
                                  return 'Exceeds advance amount';
                                }
                                return null;
                              },
                            ),
                          if (_currentAdvance != null)
                            Text(
                              'Available Advance: ${_currentAdvance!.toStringAsFixed(2)}',
                            ),
                          TextFormField(
                            controller: _lateFineController,
                            decoration: InputDecoration(
                              labelText: 'Late Fine',
                              hintText: 'Enter late fine amount',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextFormField(
                            controller: _absentFineController,
                            decoration: InputDecoration(
                              labelText: 'Absent Fine',
                              hintText: 'Enter absent fine amount',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextFormField(
                            controller: _loanController,
                            decoration: InputDecoration(
                              labelText: 'Loan Amount',
                              hintText: 'Enter loan amount',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextFormField(
                            controller: _medicalInsuranceController,
                            decoration: InputDecoration(
                              labelText: 'Medical Insurance Deduction',
                              hintText: 'Enter medical insurance deduction',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          // TextFormField(
                          //   controller: _pfController,
                          //   decoration: InputDecoration(
                          //     labelText: 'PF Deduction',
                          //     hintText: 'Enter PF deduction',
                          //   ),
                          //   keyboardType: TextInputType.number,
                          // ),
                          SizedBox(height: 5.sp),
                        ],

                        // END OF NEW ADVANCE DEDUCTION UI
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(labelText: 'Amount'),
                          keyboardType: TextInputType.number,
                          readOnly: paymentType == 'full_salary',
                          enabled: paymentType != 'full_salary',
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Required';
                            final amount = double.tryParse(value);
                            if (amount == null) return 'Invalid amount';
                            if (paymentType == 'commission' &&
                                amount > (_unpaidSalary ?? 0))
                              return 'Exceeds unpaid salary';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _clearFields();
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => _processPayment(paymentType, context),
                    child: Text('Confirm'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _searchEmployee(String userId, StateSetter setState) async {
    try {
      final response =
          await _supabase
              .from('employers')
              .select()
              .eq('employee_id', userId)
              .single();

      setState(() {
        _selectedEmployee = response;
        _unpaidSalary = (response['unpaid_salary'] ?? 0).toDouble();
        _unpaidCommission = (response['commission_unpaid'] ?? 0).toDouble();
        _finalUnpaidSalary =
            (response['unpaid_salary'] ?? 0).toDouble() +
            (response['incentives'] ?? 0).toDouble();

        // Set commission controller to unpaid commission value
        _commissionController.text =
            _unpaidCommission?.toStringAsFixed(0) ?? '0';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Employee not found')));
    }
  }

  Future<void> _processPayment(String paymentType, BuildContext context) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      SupabaseExceptionHandler.showErrorSnackbar(context, 'Invalid Amount');
      return;
    }

    try {
      final employeeResponse =
          await _supabase
              .from('employers')
              .select(
                'id, advance_amount, unpaid_salary, commission_unpaid, incentives, hra_amount, medical_allowance, conveyance_allowance',
              )
              .eq('employee_id', _userIdController.text)
              .single();

      final employeeUuid = employeeResponse['id'] as String;
      double currentAdvance =
          (employeeResponse['advance_amount'] ?? 0.0).toDouble();
      final currentUnpaid =
          (employeeResponse['unpaid_salary'] ?? 0.0).toDouble();
      final currentCommissionUnpaid =
          (employeeResponse['commission_unpaid'] ?? 0.0).toDouble();
      final currentIncentives =
          (employeeResponse['incentives'] ?? 0.0).toDouble();

      double advanceDeduction = 0.0;
      double commissionPaidNow = 0.0;

      if (paymentType == 'full_salary') {
        // Get commission payment from the controller
        commissionPaidNow = double.tryParse(_commissionController.text) ?? 0.0;

        // Validate commission payment
        if (commissionPaidNow > currentCommissionUnpaid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Commission payment exceeds unpaid commission'),
            ),
          );
          return;
        }

        // Update commission in database if commission is being paid
        if (commissionPaidNow > 0) {
          final newCommissionUnpaid =
              currentCommissionUnpaid - commissionPaidNow;
          await _supabase
              .from('employers')
              .update({'commission_unpaid': newCommissionUnpaid})
              .eq('employee_id', _userIdController.text);
        }

        // Parse all the allowance and deduction amounts for net pay calculation
        double otherAllowanceAmount =
            double.tryParse(_otherController.text) ?? 0.0;
        double lateFineAmount =
            double.tryParse(_lateFineController.text) ?? 0.0;
        double absentFineAmount =
            double.tryParse(_absentFineController.text) ?? 0.0;
        double loanAmount = double.tryParse(_loanController.text) ?? 0.0;
        double medicalInsuranceDeductionAmount =
            double.tryParse(_medicalInsuranceController.text) ?? 0.0;
        double pfDeductionAmount = double.tryParse(_pfController.text) ?? 0.0;

        if (_resetAdvance) {
          advanceDeduction =
              double.tryParse(_advanceDeductController.text) ?? 0.0;

          if (advanceDeduction > currentAdvance) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deduction exceeds advance amount')),
            );
            return;
          }

          // Update advance amount in employer record
          currentAdvance -= advanceDeduction;
          await _supabase
              .from('employers')
              .update({'advance_amount': currentAdvance})
              .eq('employee_id', _userIdController.text);
        }

        // Calculate net pay (same as in PDF)
        double basicSalary =
            (employeeResponse['unpaid_salary'] ?? 0.0).toDouble();
        double hraAmount = (employeeResponse['hra_amount'] ?? 0.0).toDouble();
        double medicalAllowanceAmount =
            (employeeResponse['medical_allowance'] ?? 0.0).toDouble();
        double conveyanceAllowanceAmount =
            (employeeResponse['conveyance_allowance'] ?? 0.0).toDouble();
        double incentiveAmount =
            (employeeResponse['incentives'] ?? 0.0).toDouble();

        // Determine whether to use commission or incentive
        bool hasUnpaidCommission = currentCommissionUnpaid > 0;
        double commissionOrIncentiveAmount =
            hasUnpaidCommission ? commissionPaidNow : incentiveAmount;

        // Total earnings calculation
        double totalEarnings =
            basicSalary +
            hraAmount +
            medicalAllowanceAmount +
            conveyanceAllowanceAmount +
            commissionOrIncentiveAmount +
            otherAllowanceAmount;

        // Total deductions calculation
        double totalDeductions =
            lateFineAmount +
            absentFineAmount +
            advanceDeduction +
            loanAmount +
            medicalInsuranceDeductionAmount +
            pfDeductionAmount;

        // Net pay calculation (same as PDF) - THIS IS WHAT SHOWS ON PDF
        double netPay = totalEarnings - totalDeductions;

        // Record in paid_salaries
        await _supabase.from('paid_salaries').insert({
          'employee_id': _userIdController.text.toLowerCase(),
          'amount': netPay,
          'payment_date': DateTime.now().toIso8601String(),
          'type': 'full_salary',
        });

        // Record in cash_flow_transactions
        String description =
            'FULL SALARY to ${_selectedEmployee!['name']} (ID: ${_userIdController.text})';

        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          await _supabase.from('cash_flow_transactions').insert({
            'user_id': currentUser.id,
            'employee_id': _userIdController.text.toLowerCase(),
            'amount': netPay,
            'description': description,
            'date': DateTime.now().toIso8601String(),
            'category': 'full_salary',
            'type': 'expense',
          });

          // Update unpaid salary
          final newUnpaid = currentUnpaid - amount;
          final isFullPayment = newUnpaid <= 0;

          await _supabase
              .from('employers')
              .update({
                'unpaid_salary': newUnpaid > 0 ? newUnpaid : 0,
                'is_salary_paid': isFullPayment,
                'incentives': 0.0, // Reset incentives on full salary payment
              })
              .eq('employee_id', _userIdController.text);
        }

        // Generate salary slip for full salary
        await _generateSalarySlip(
          employee: _selectedEmployee!,
          amount: amount,
          paymentType: 'Full Salary',
          remainingUnpaid: currentUnpaid - amount,
          advanceDeduction: advanceDeduction,
          totalCommissionUnpaid:
              currentCommissionUnpaid, // Pass total unpaid commission (before payment)
          commissionPaidNow:
              commissionPaidNow, // Pass commission being paid now
          scaffoldContext: context,
        );
      } else if (paymentType == 'commission') {
        // Handle commission payment only
        if (amount > currentCommissionUnpaid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot pay more than unpaid commission')),
          );
          return;
        }

        commissionPaidNow = amount;
        final newCommissionUnpaid = currentCommissionUnpaid - commissionPaidNow;

        // Update commission in database
        await _supabase
            .from('employers')
            .update({'commission_unpaid': newCommissionUnpaid})
            .eq('employee_id', _userIdController.text);

        // Record in paid_salaries
        await _supabase.from('paid_salaries').insert({
          'employee_id': _userIdController.text.toLowerCase(),
          'amount': commissionPaidNow,
          'payment_date': DateTime.now().toIso8601String(),
          'type': 'commission',
        });

        // Record in cash_flow_transactions
        String description =
            'COMMISSION PAYMENT to ${_selectedEmployee!['name']} (ID: ${_userIdController.text})';

        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          await _supabase.from('cash_flow_transactions').insert({
            'user_id': currentUser.id,
            'employee_id': _userIdController.text.toLowerCase(),
            'amount': commissionPaidNow,
            'description': description,
            'date': DateTime.now().toIso8601String(),
            'category': 'commission',
            'type': 'expense',
          });
        }
      } else if (paymentType == 'advance') {
        // Handle advance payment
        // Update advance amount
        await _supabase
            .from('employers')
            .update({'advance_amount': currentAdvance + amount})
            .eq('employee_id', _userIdController.text);

        // Record in paid_salaries
        await _supabase.from('paid_salaries').insert({
          'employee_id': _userIdController.text.toLowerCase(),
          'amount': amount,
          'payment_date': DateTime.now().toIso8601String(),
          'type': 'advance',
        });

        // Record in cash_flow_transactions
        String description =
            'ADVANCE PAYMENT to ${_selectedEmployee!['name']} (ID: ${_userIdController.text})';

        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          await _supabase.from('cash_flow_transactions').insert({
            'user_id': currentUser.id,
            'employee_id': _userIdController.text.toLowerCase(),
            'amount': amount,
            'description': description,
            'date': DateTime.now().toIso8601String(),
            'category': 'advance',
            'type': 'expense',
          });
        }
      }

      // Common success actions for all payment types
      _fetchEmployees();
      Navigator.pop(context);
      _clearFields();

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        '${paymentType.replaceAll('_', ' ')} processed successfully',
      );
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Something went wrong\n Please update your software or contact developer.',
      );
    }
  }

  void _clearFields() {
    _userIdController.clear();
    _amountController.clear();
    _selectedEmployee = null;
    _unpaidSalary = null;
    _unpaidCommission = null; // ADDED
    _hraController.clear();
    _medicalController.clear();
    _conveyanceController.clear();
    _incentiveController.clear();
    _otherController.clear();
    _lateFineController.clear();
    _absentFineController.clear();
    _loanController.clear();
    _medicalInsuranceController.clear();
    _pfController.clear();
    _advanceDeductController.clear();
    _resetAdvance = false;
    _currentAdvance = null;
  }

  Future<void> _generateSalarySlip({
    required BuildContext scaffoldContext,
    required Map<String, dynamic> employee,
    required double amount,
    required String paymentType,
    required double remainingUnpaid,
    // addons
    double hraAmount = 0.0,
    double medicalAllowanceAmount = 0.0,
    double conveyanceAllowanceAmount = 0.0,
    double incentiveAmount = 0.0,
    double otherAllowanceAmount = 0.0,
    //deductions
    double lateFineAmount = 0.0,
    double absentFineAmount = 0.0,
    double loanAmount = 0.0,
    double medicalInsuranceDeductionAmount = 0.0,
    double pfDeductionAmount = 0.0,
    double advanceDeduction = 0.0,
    // Commission parameters
    double totalCommissionUnpaid =
        0.0, // Total unpaid commission before this payment
    double commissionPaidNow = 0.0, // Commission being paid in this salary slip
  }) async {
    final pdf.Document document = pw.Document();
    final lightBlue = pdf.PdfColor.fromHex('#DDEBF7');
    final tableBorder = pw.TableBorder.all(
      color: pdf.PdfColors.black,
      width: 0.7,
    );

    // If not using custom fonts, define some basic styles:
    final baseStyle = pw.TextStyle(fontSize: 12);
    final headingbaseStyle = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final boldStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );
    final companyNameStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.values[1],
      fontSize: 26,
    );
    final headerCellStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 13,
    );

    // Helper function to safely get string values
    String _getString(dynamic value, {String defaultValue = 'N/A'}) {
      if (value == null || value.toString().toLowerCase() == 'null') {
        return defaultValue;
      }
      return value.toString();
    }

    // Helper function to safely parse and format dates
    String _getFormattedDate(
      dynamic dateValue, {
      String format = 'dd/MM/yyyy',
      String defaultValue = 'N/A',
    }) {
      if (dateValue == null) return defaultValue;
      DateTime? date;
      if (dateValue is String) {
        try {
          if (dateValue.isEmpty || dateValue.toLowerCase() == 'null')
            return defaultValue;
          date = DateTime.parse(dateValue);
        } catch (e) {
          return dateValue;
        }
      } else if (dateValue is DateTime) {
        date = dateValue;
      }
      return date != null ? DateFormat(format).format(date) : defaultValue;
    }

    String _formatCurrency(double value) {
      return value.toStringAsFixed(2);
    }

    // Calculate values with null safety
    final double basicSalary = (employee['salary'] ?? 0.0).toDouble();
    final double unpaidSalary = (employee['unpaid_salary'] ?? 0.0).toDouble();
    final double hraAmount = (employee['hra_amount'] ?? 0.0).toDouble();
    final double medicalAllowanceAmount =
        (employee['medical_allowance'] ?? 0.0).toDouble();
    final double conveyanceAllowanceAmount =
        (employee['conveyance_allowance'] ?? 0.0).toDouble();
    final double incentiveAmount = (employee['incentives'] ?? 0.0).toDouble();
    final double otherAllowanceAmount =
        double.tryParse(_otherController.text) ?? 0.0;

    // Commission calculations
    final bool hasUnpaidCommission = totalCommissionUnpaid > 0;
    final double balanceCommission = totalCommissionUnpaid - commissionPaidNow;

    // Calculate total earnings - Use commissionPaidNow if there's unpaid commission, otherwise incentive
    // IMPORTANT: Always show commissionPaidNow in earnings when paying commission
    final double commissionOrIncentiveAmount =
        hasUnpaidCommission ? commissionPaidNow : incentiveAmount;

    final totalEarnings =
        unpaidSalary +
        hraAmount +
        medicalAllowanceAmount +
        conveyanceAllowanceAmount +
        commissionOrIncentiveAmount +
        otherAllowanceAmount;

    // Get deduction amounts
    final double lateFineAmount =
        double.tryParse(_lateFineController.text) ?? 0.0;
    final double absentFineAmount =
        double.tryParse(_absentFineController.text) ?? 0.0;
    final double loanAmount = double.tryParse(_loanController.text) ?? 0.0;
    final double medicalInsuranceDeductionAmount =
        double.tryParse(_medicalInsuranceController.text) ?? 0.0;
    final double pfDeductionAmount = double.tryParse(_pfController.text) ?? 0.0;

    // Calculate total deductions (NO commission in deductions)
    final totalDeductions =
        lateFineAmount +
        absentFineAmount +
        advanceDeduction +
        loanAmount +
        medicalInsuranceDeductionAmount +
        pfDeductionAmount;

    final netPay = totalEarnings - totalDeductions;

    final String salaryMonthString = _getFormattedDate(
      DateTime.now(),
      format: 'MMMM yyyy',
    );
    final String currentDateString = _getFormattedDate(DateTime.now());

    // Helper for Employee Detail Items in the Row/Column structure
    pw.Widget _buildDetailItem(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 90, child: pw.Text('$label:', style: boldStyle)),
            pw.SizedBox(width: 5),
            pw.Expanded(child: pw.Text(value, style: baseStyle)),
          ],
        ),
      );
    }

    // Helper for Summary Table Rows
    pw.TableRow _buildSummaryRow(
      String label,
      double value, {
      bool isBold = false,
      bool isTotal = false,
    }) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(label, style: isBold ? boldStyle : baseStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                _formatCurrency(value),
                style: isBold ? boldStyle : baseStyle,
              ),
            ),
          ),
        ],
      );
    }

    // Helper for Earnings/Deductions Table Header Cells
    pw.Widget _buildHeaderCell(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: headerCellStyle,
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    // Helper for Earnings/Deductions Table Amount Cells
    pw.Widget _buildAmountCell(double value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(_formatCurrency(value), style: baseStyle),
        ),
      );
    }

    // Helper for Earnings/Deductions Table Text Cells
    pw.Widget _buildTextCell(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text, style: baseStyle),
      );
    }

    // Helper to build rows for Earnings & Deductions
    List<pw.TableRow> _buildEarningsDeductionsRows() {
      // Earnings array - show Commission if has unpaid commission, otherwise Incentive
      final earnings = [
        {'label': 'Salary', 'value': unpaidSalary},
        {'label': 'HRA', 'value': hraAmount},
        {'label': 'Medical Allow', 'value': medicalAllowanceAmount},
        {'label': 'Conveyance Allow', 'value': conveyanceAllowanceAmount},
        {
          'label': hasUnpaidCommission ? 'Commission' : 'Incentive',
          'value':
              commissionPaidNow, // This shows the actual commission being paid
        },
        {'label': 'Other Allow', 'value': otherAllowanceAmount},
      ];

      // Deductions array - NO commission in deductions
      final deductions = [
        {'label': 'Late Fine', 'value': lateFineAmount},
        {'label': 'Absent Fine', 'value': absentFineAmount},
        {'label': 'Advance', 'value': advanceDeduction},
        {'label': 'Loan', 'value': loanAmount},
        {
          'label': 'Medical Insurance',
          'value': medicalInsuranceDeductionAmount,
        },
        {'label': 'PF', 'value': pfDeductionAmount},
      ];

      final List<pw.TableRow> rows = [];
      final int maxRows =
          earnings.length > deductions.length
              ? earnings.length
              : deductions.length;

      for (int i = 0; i < maxRows; i++) {
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(),
            children: [
              i < earnings.length
                  ? _buildTextCell(earnings[i]['label'] as String)
                  : pw.Container(),
              i < earnings.length
                  ? _buildAmountCell(earnings[i]['value'] as double)
                  : pw.Container(),
              i < deductions.length
                  ? _buildTextCell(deductions[i]['label'] as String)
                  : pw.Container(),
              i < deductions.length
                  ? _buildAmountCell(deductions[i]['value'] as double)
                  : pw.Container(),
            ],
          ),
        );
      }
      return rows;
    }

    // Helper for Underlined Text
    pw.Widget _buildUnderlinedText(String text, {double lineWidth = 50}) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(text, style: baseStyle),
          pw.Container(
            height: 0.5,
            width: lineWidth,
            color: pdf.PdfColors.black,
          ),
        ],
      );
    }

    // Helper for Signature Fields
    pw.Widget _buildSignatureField(String label) {
      return pw.Column(
        children: [
          pw.Container(
            width: 120,
            height: 8,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: pdf.PdfColors.black, width: 0.5),
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(label, style: baseStyle),
        ],
      );
    }

    document.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 43),
                // Header Section
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Reliable Marketing Network',
                      style: companyNameStyle,
                    ),
                    pw.Text('Pvt Ltd.', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Salary Month:', style: headingbaseStyle),
                        _buildUnderlinedText(
                          '  $salaryMonthString',
                          lineWidth: 150,
                        ),
                      ],
                    ),

                    pw.Row(
                      children: [
                        pw.Text('Date:', style: headingbaseStyle),

                        _buildUnderlinedText(
                          '  $currentDateString',
                          lineWidth: 100,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 15),

                // Salary Slip Title Bar
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    color: lightBlue,
                  ),
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 5,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'SALARY SLIP',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: pdf.PdfColors.black,
                    ),
                  ),
                ),

                pw.SizedBox(height: 5),
                // Employee Details using Row and Column
                pw.Container(
                  decoration: pw.BoxDecoration(border: tableBorder),
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Column for Employee Details
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                              'ID',
                              _getString(
                                employee['employee_id']
                                    ?.toString()
                                    .toUpperCase(),
                              ),
                            ),
                            _buildDetailItem(
                              'Name',
                              _getString(employee['name']),
                            ),
                            _buildDetailItem(
                              'Designation',
                              _getString(employee['designation']),
                            ),
                            _buildDetailItem(
                              'Department',
                              _getString(employee['department']),
                            ),
                            _buildDetailItem(
                              'D/O Joining',
                              _getFormattedDate(employee['hire_date']),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Container(
                        color: pdf.PdfColors.black,
                        height: 100,
                        width: 1,
                      ),
                      pw.SizedBox(width: 10),
                      // Right Column for Contact/Bank Info
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                              'Contact',
                              _getString(employee['phone']),
                            ),
                            _buildDetailItem(
                              'PF No.',
                              _getString(employee['pf_no_val']),
                            ),
                            _buildDetailItem(
                              'Insurance No.',
                              _getString(employee['insurance_no_val']),
                            ),
                            _buildDetailItem(
                              'Bank',
                              _getString(employee['bank_name']),
                            ),
                            _buildDetailItem(
                              'Account No.',
                              _getString(employee['account_no_val']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // Summary Table (Gross, Deduction, Net Income)
                pw.Table(
                  border: tableBorder,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    _buildSummaryRow('Gross Income', totalEarnings),
                    _buildSummaryRow('Total Deduction', totalDeductions),
                    _buildSummaryRow(
                      'Net Income',
                      netPay,
                      isBold: true,
                      isTotal: true,
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Commission Summary Section - Show even if no commission, but with 0 values
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: tableBorder,
                    color: lightBlue,
                  ),
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: pw.Text(
                    'COMMISSION SUMMARY',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: pdf.PdfColors.black,
                    ),
                  ),
                ),

                pw.Table(
                  border: tableBorder,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    _buildSummaryRow('Total Commission', totalCommissionUnpaid),
                    // _buildSummaryRow('Commission Paid', commissionPaidNow),
                    _buildSummaryRow(
                      'Commission Balance',
                      balanceCommission,
                      // isBold: true,
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Earnings & Deductions Table
                pw.Table(
                  border: tableBorder,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: lightBlue,
                        border: pw.Border(),
                      ),
                      children: [
                        _buildHeaderCell('Earnings'),
                        _buildHeaderCell('Amount'),
                        _buildHeaderCell('Deductions'),
                        _buildHeaderCell('Amount'),
                      ],
                    ),
                    ..._buildEarningsDeductionsRows(),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: lightBlue,
                        border: pw.Border(),
                      ),
                      children: [
                        _buildTextCell('Total Income'),
                        _buildAmountCell(totalEarnings),
                        _buildTextCell('Total Deduction'),
                        _buildAmountCell(totalDeductions),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 5),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: context.page.pageFormat.availableWidth / 2,
                    child: pw.Table(
                      border: tableBorder,
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
                                'Net Pay',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.left,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                _formatCurrency(netPay),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 80),
                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSignatureField('Authorized By'),
                    _buildSignatureField('Manager Sign'),
                    _buildSignatureField('Employee Sign'),
                  ],
                ),
              ],
            ),
      ),
    );

    final Uint8List pdfData = await document.save();

    String _sanitizeFileName(String name) {
      return name
          .replaceAll(RegExp(r'[\s/\\]+'), '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    }

    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        if (scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            const SnackBar(
              content: Text('Could not access downloads directory'),
            ),
          );
        }
        return;
      }

      final employeeNameSanitized = _sanitizeFileName(
        _getString(employee['name'], defaultValue: 'Employee'),
      );
      final fileName =
          'SalarySlip_${employeeNameSanitized}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(directory.path, fileName);

      final File file = File(filePath);
      await file.writeAsBytes(pdfData);

      if (scaffoldContext.mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Salary slip saved to Downloads: $fileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final result = await OpenFile.open(filePath);
                if (result.type != ResultType.done && scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('Could not open file: ${result.message}'),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (scaffoldContext.mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Helper functions
  // Future<pw.Font> _loadGoogleFont(String fontName, {bool bold = false}) async {
  //   final fontData = await rootBundle.load(
  //     bold
  //         ? 'assets/fonts/${fontName}-Bold.ttf'
  //         : 'assets/fonts/${fontName}-Regular.ttf',
  //   );
  //   return pw.Font.ttf(fontData);
  // }

  pw.TableRow _buildEmployeeDetailRow(String label, dynamic value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value.toString()),
        ),
        pw.Container(),
        pw.Container(),
      ],
    );
  }

  pw.TableRow _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(label)),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            _formatCurrency(amount),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<pw.TableRow> _buildEarningsDeductionsRows(
    Map<String, dynamic> employee,
  ) {
    final earnings = [
      ['Basic Salary', employee['salary']],
      ['HRA', employee['hra_amount']],
      ['Medical Allow', employee['medical_allowance_amount']],
      ['Conveyance Allow', employee['conveyance_allowance_amount']],
      ['Incentive', employee['incentive_amount']],
      ['Other Allow', employee['other_allowance_amount']],
    ];

    final deductions = [
      ['Late Fine', employee['late_fine_amount']],
      ['Absent Fine', employee['absent_fine_amount']],
      ['Advance', employee['advance_amount']],
      ['Loan', employee['loan_amount']],
      ['Medical Insurance', employee['medical_insurance_deduction_amount']],
      ['PF', employee['pf_deduction_amount']],
    ];

    final rows = <pw.TableRow>[];
    for (int i = 0; i < 6; i++) {
      rows.add(
        pw.TableRow(
          children: [
            _buildCell(earnings[i][0]),
            _buildAmountCell(earnings[i][1]),
            _buildCell(deductions[i][0]),
            _buildAmountCell(deductions[i][1]),
          ],
        ),
      );
    }
    return rows;
  }

  pw.Widget _buildSignatureField(String label) {
    return pw.Column(
      children: [
        pw.Text(label),
        pw.Container(
          width: 100,
          height: 1,
          margin: const pw.EdgeInsets.only(top: 4),
          decoration: const pw.BoxDecoration(color: pdf.PdfColors.black),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount);
  }

  pw.Widget _buildUnderlinedText(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(text),
        pw.Container(width: 100, height: 1, color: pdf.PdfColors.black),
      ],
    );
  }

  pw.Padding _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Padding _buildCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text),
    );
  }

  pw.Padding _buildAmountCell(dynamic amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        _formatCurrency(amount is double ? amount : 0.0),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  // Update the PDF generation method
  Future<void> _generatePdfStatement(String employeeId) async {
    try {
      final response = await _supabase
          .from('paid_salaries')
          .select('''
          *, 
          employers!inner(
            name,
            employee_id,
            designation
          )
        ''')
          .eq('employee_id', employeeId)
          .order('payment_date');

      final payments = List<Map<String, dynamic>>.from(response);

      if (payments.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No payment history found')),
          );
        }
        return;
      }

      final document = pw.Document(
        title: 'Salary Statement',
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
      );

      // Load logo (placeholder implementation)
      final logo = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
      );

      // Calculate totals and dates
      final totalAmount = payments.fold<double>(
        0,
        (sum, payment) => sum + (payment['amount'] as num).toDouble(),
      );
      final firstDate = DateTime.parse(payments.first['payment_date']);
      final lastDate = DateTime.parse(payments.last['payment_date']);

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 1.5 * PdfPageFormat.cm,
            marginRight: 1.5 * PdfPageFormat.cm,
            marginTop: 1.0 * PdfPageFormat.cm,
            marginBottom: 1.0 * PdfPageFormat.cm,
          ),
          build:
              (pdfContext) => pw.Stack(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildHeader(logo, pdfContext),
                      _buildEmployeeInfo(
                        payments.first['employers'],
                        firstDate,
                        lastDate,
                      ),
                      pw.SizedBox(height: 15),
                    ],
                  ),
                  pw.Positioned(
                    top: 220, // Adjust based on header height
                    left: 0,
                    right: 0,
                    bottom: 50, // Space for footer
                    child: pw.Column(
                      children: [
                        pw.Expanded(
                          child: _buildPaymentTable(pdfContext, payments),
                        ),
                        _buildTotalSection(totalAmount),
                      ],
                    ),
                  ),
                  pw.Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildFooter(pdfContext),
                  ),
                ],
              ),
        ),
      );

      final Uint8List pdfData = await document.save();
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'salary-statement-$employeeId.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        SupabaseExceptionHandler.showErrorSnackbar(context, e.toString());
      }
    }
  }

  pw.Widget _buildHeader(pw.ImageProvider logo, pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(logo, height: 60),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _companyName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(_companyAddress, style: pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'Tel: $_companyPhone | Email: $_companyEmail',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
        pw.Center(
          child: pw.Text(
            'SALARY PAYMENT STATEMENT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.blue800,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildEmployeeInfo(
    Map<String, dynamic> employer,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: pdf.PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: pw.EdgeInsets.all(10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Employee Name:', employer['name']),
              _infoRow(
                'Employee ID:',
                employer['employee_id'].toString().toUpperCase(),
              ),
              _infoRow('Designation:', employer['designation']),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _infoRow(
                'Statement Period:',
                '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
              ),
              _infoRow(
                'Generated On:',
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentTable(
    pw.Context pdfContext,
    List<Map<String, dynamic>> payments,
  ) {
    return pw.TableHelper.fromTextArray(
      context: pdfContext,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(1.5), // Type
        2: const pw.FlexColumnWidth(1), // Amount
        3: const pw.FlexColumnWidth(3), // Payment ID
      },
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      headers: ['Date', 'Type', 'Amount', 'Payment ID'],

      data:
          payments
              .map(
                (payment) => [
                  DateFormat(
                    'dd/MM/yyyy',
                  ).format(DateTime.parse(payment['payment_date'])),
                  (payment['type'] as String).toUpperCase(),
                  payment['amount'].toStringAsFixed(0),
                  payment['id'].toString(), // Ensure string conversion
                ],
              )
              .toList(),

      defaultColumnWidth: const pw.FlexColumnWidth(1), // Fallback
      headerPadding: const pw.EdgeInsets.all(5),
      cellPadding: const pw.EdgeInsets.all(5),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerHeight: 25,
      cellHeight: 20,
    );
  }

  pw.Widget _buildTotalSection(double totalAmount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: pdf.PdfColors.blue800),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          padding: pw.EdgeInsets.all(10),
          margin: pw.EdgeInsets.only(top: 15),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Paid:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Generated by RMN Accounts',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Confidential - For Authorized Use Only',
          style: pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 5),
        pw.Text(value),
      ],
    );
  }

  void _handleEmployeeAction(
    String action,
    Map<String, dynamic> employee,
  ) async {
    switch (action) {
      case 'edit':
        final verified = await AdminVerification.showVerificationDialog(
          context: context,
          action: 'edit employee ${employee['name']}',
        );

        if (verified && context.mounted) {
          _showEditEmployeeDialog(employee);
        }
        break;

      case 'delete':
        final verified = await AdminVerification.showVerificationDialog(
          context: context,
          action: 'delete employee ${employee['name']}',
        );
        break;
      case 'update_profile_picture':
        final verified = await AdminVerification.showVerificationDialog(
          context: context,
          action: 'update profile picture for ${employee['name']}',
        );
        if (verified && context.mounted) {
          await _updateProfilePicture(employee);
        }
        break;

      case 'add/update_documents':
        final verified = await AdminVerification.showVerificationDialog(
          context: context,
          action: 'update documents for ${employee['name']}',
        );
        if (verified && context.mounted) {
          await _updateDocument(employee);
        }

        if (verified && context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: Text(
                    'Are you sure you want to delete ${employee['name']}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
          );

          if (confirmed == true) {
            try {
              await _supabase
                  .from('employers')
                  .delete()
                  .eq('id', employee['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${employee['name'].toString().toUpperCase()} deleted',
                    ),
                  ),
                );
                _fetchEmployees();
              }
            } catch (e) {
              if (context.mounted) {
                SupabaseExceptionHandler.showErrorSnackbar(
                  context,
                  'Error deleting employee',
                );
              }
            }
          }
        }
        break;

      case 'Active/Non-Active':
        final verified = await AdminVerification.showVerificationDialog(
          context: context,
          action:
              '${employee['status'] == 'active' ? 'deactivate' : 'activate'} employee ${employee['name'].toString().toUpperCase()}',
        );

        if (verified && context.mounted) {
          final newStatus =
              employee['status'] == 'active' ? 'inactive' : 'active';
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Confirm Status Change'),
                  content: Text(
                    'Do you want to ${newStatus == 'active' ? 'activate' : 'deactivate'} ${employee['name']}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
          );

          if (confirmed == true) {
            try {
              newStatus == 'active'
                  ? await _supabase
                      .from('employers')
                      .update({'status': newStatus, 'expire_date': null})
                      .eq('id', employee['id'])
                  : await _supabase
                      .from('employers')
                      .update({
                        'status': newStatus,
                        'expire_date': DateTime.now().toIso8601String(),
                      })
                      .eq('id', employee['id']);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status updated to ${newStatus}')),
                );
                _fetchEmployees();
              }
            } catch (e) {
              if (context.mounted) {
                SupabaseExceptionHandler.showErrorSnackbar(
                  context,
                  'Error updating status',
                );
              }
            }
          }
        }
        break;
    }
  }

  void _showEditEmployeeDialog(Map<String, dynamic> employee) {
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddEmployeeForm(employee: employee),
          ),
    ).then((_) => _fetchEmployees());
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color color,
    String employeeId,
    String? activeText,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Employee ID:',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                text,
                style: TextStyle(fontSize: 11.sp, color: Colors.blueGrey[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(width: 9.sp),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, size: 15.sp),
            onPressed: () => _generatePdfStatement(employeeId),
          ),
        ],
      ),
    );
  }

  // Future<void> _updateProfilePicture(Map<String, dynamic> employee) async {
  //   final pickedFile = await ImagePicker().pickImage(
  //     source: ImageSource.gallery,
  //   );
  //   if (pickedFile == null) return;

  //   final loadingProvider = Provider.of<LoadingProvider>(
  //     context,
  //     listen: false,
  //   );
  //   loadingProvider.startLoading();

  //   try {
  //     final file = File(pickedFile.path);

  //     // Validate image type
  //     final mimeType = lookupMimeType(file.path);
  //     if (!['image/jpeg', 'image/png', 'image/webp'].contains(mimeType)) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Only JPG/PNG images allowed')),
  //       );
  //       return;
  //     }

  //     final url = await SupabaseStorageService.uploadFile(
  //       bucket: 'profile_pictures',
  //       userId: employee['id'].toString(),
  //       file: file,
  //       fileType: 'image',
  //     );

  //     if (url != null) {
  //       await _supabase
  //           .from('employers')
  //           .update({'profile_picture_url': url})
  //           .eq('id', employee['id']);
  //       _fetchEmployees();
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to update profile picture: $e')),
  //     );
  //   } finally {
  //     loadingProvider.stopLoading();
  //   }
  // }

  Future<void> _updateProfilePicture(Map<String, dynamic> employee) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null) return;

    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      var file = File(result.files.single.path!);

      // Compress and validate
      file = await FileUtils.compressAndValidateFile(
        file,
        isImage: true,
        quality: 80,
      );

      final url = await SupabaseStorageService.uploadFile(
        bucket: 'profilepictures',
        userId: employee['id'].toString(),
        file: file,
      );

      if (url != null) {
        await _supabase
            .from('employers')
            .update({'profile_picture_url': url})
            .eq('id', employee['id']);
        _fetchEmployees();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Future<void> _updateDocument(Map<String, dynamic> employee) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'tiff'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      for (var platformFile in result.files) {
        if (platformFile.path == null) continue;

        var file = File(platformFile.path!);

        // Validate document type
        if (!await FileUtils.isScannedDocument(file)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only scanned PDF/JPEG/PNG/TIFF documents allowed'),
            ),
          );
          continue;
        }

        // Compress and validate size
        file = await documentsFileUtils.compressAndValidateFile(
          file,
          isImage: !file.path.endsWith('.pdf'),
          quality: 70,
        );

        final url = await SupabaseStorageService.uploadFile(
          bucket: 'documents',
          userId: employee['id'].toString(),
          file: file,
        );

        if (url != null) {
          // Insert into new documents table
          await _supabase.from('employee_documents').insert({
            'employee_id': employee['id'],
            'document_url': url,
            'document_name': platformFile.name,
          });
        }
      }

      _fetchEmployees();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload document: $e')));
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Future<void> _generateDocumentsPdf(Map<String, dynamic> employee) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      // Fetch all documents for this employee
      final response = await _supabase
          .from('employee_documents')
          .select()
          .eq('employee_id', employee['id'])
          .order('created_at');

      final documents = List<Map<String, dynamic>>.from(response);

      if (documents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No documents found for this employee')),
        );
        return;
      }

      // Create PDF
      final pdf = pw.Document();
      final employeeName = employee['name'] ?? 'Employee';

      // pdf.addPage(
      //   pw.Page(
      //     build:
      //         (context) => pw.Column(
      //           crossAxisAlignment: pw.CrossAxisAlignment.start,
      //           children: [
      //             pw.Header(
      //               level: 0,
      //               child: pw.Text('Documents for $employeeName'),
      //             ),
      //             pw.Divider(),
      //             pw.SizedBox(height: 20),
      //             ...documents.map((doc) => _buildDocumentItem(doc)).tofList(),
      //           ],
      //         ),
      //   ),
      // );

      // Add pages for images and handle PDFs
      for (var doc in documents) {
        final mimeType = lookupMimeType(doc['document_name'] ?? '') ?? '';

        if (mimeType.startsWith('image/')) {
          try {
            final imageBytes = await _downloadFile(doc['document_url']);
            if (imageBytes != null) {
              // Create a PDF document from the bytes
              final image = pw.MemoryImage(imageBytes);
              pdf.addPage(
                pw.Page(
                  build:
                      (context) => pw.Center(
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                ),
              );
            }
          } catch (e) {
            SupabaseExceptionHandler.showErrorSnackbar(
              context,
              'Failed to load image: ${doc['document_name']}',
            );
          }
        }
      }

      // Save PDF to downloads
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Could not access downloads directory');

      final fileName =
          '${employeeName.replaceAll(' ', '_')}_Documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the PDF
      OpenFile.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to Downloads: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Future<Uint8List?> _downloadFile(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        return await consolidateHttpClientResponseBytes(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  pw.Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final mimeType = lookupMimeType(doc['document_name'] ?? '') ?? '';
    final isImage = mimeType.startsWith('image/');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // pw.Text(
        //   doc['document_name'] ?? 'Document',
        //   style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        // ),
        // pw.SizedBox(height: 5),
        // if (isImage)
        //   pw.Text(
        //     '[IMAGE EMBEDDED IN NEXT PAGE]',
        //     style: pw.TextStyle(fontSize: 10),
        //   )
        // else
        //   pw.UrlLink(
        //     destination: doc['document_url'],
        //     child: pw.Text(
        //       'Open Document',
        //       style: pw.TextStyle(
        //         color: PdfColors.blue,
        //         decoration: pw.TextDecoration.underline,
        //       ),
        //     ),
        //   ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // pw.Widget _buildDocumentItem(Map<String, dynamic> doc) {
  //   return pw.Column(
  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //     children: [
  //       pw.Text(
  //         doc['document_name'] ?? 'Document',
  //         style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
  //       ),
  //       pw.SizedBox(height: 5),
  //       pw.Text('URL: ${doc['document_url']}'),
  //       pw.Divider(thickness: 0.5),
  //       pw.SizedBox(height: 10),
  //     ],
  //   );
  // }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: Container(
              width: 70.sw,
              // Remove Expanded, let Dialog size to content
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueGrey[50]!,
                    Colors.blueGrey[50]!,
                    Color.fromARGB(255, 194, 174, 106),
                    const Color.fromARGB(255, 157, 167, 172)!,
                    const Color.fromARGB(255, 157, 167, 172)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16.sp),
              ),
              padding: EdgeInsets.all(4.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22.sp,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                        employee['profile_picture_url'] ??
                            'https://ui-avatars.com/api/?name=${employee['name']}&background=random',
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      employee['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildDetailRow(
                      'Position:',
                      employee['designation'].toString()[0].toUpperCase() +
                          employee['designation'].toString().substring(1),
                    ),
                    _buildDetailRow('Email:', employee['email']),
                    _buildDetailRow('Phone:', employee['phone']),
                    _buildDetailRow(
                      'DOB:',
                      employee['date_of_birth']?.split('T').first ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      'Address:',
                      employee['address'].toString()[0].toUpperCase() +
                          employee['address'].toString().substring(1),
                    ),
                    _buildDetailRow(
                      'Salary:',
                      '${employee['salary']?.toStringAsFixed(1) ?? '0.00'}',
                    ),
                    _buildDetailRow(
                      'Hire Date:',
                      employee['hire_date']?.split('T').first ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      'Resign Date:',
                      employee['expire_date']?.split('T').first ?? 'Active',
                    ),
                    _buildDetailRow(
                      'Contact:',
                      employee['phone']?.split('T').first ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      'Edited by:',
                      employee['edited_by'] == null
                          ? 'Not Edited'
                          : employee['edited_by'].toString()[0].toUpperCase() +
                              employee['edited_by'].toString().substring(1),
                    ),
                    if (employee['document_url'] != null) ...[
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.5.h,
                          ),
                        ),
                        child: Text('Close', style: TextStyle(fontSize: 12.sp)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // static Future<void> deleteFile(String bucket, String filePath) async {
  //   try {
  //     await _supabase.storage.from(bucket).remove([filePath]);
  //   } catch (e) {
  //     print('Delete error: $e');
  //   }
  // }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            value ?? 'Not available',
            style: TextStyle(fontSize: 12.sp, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const AddEmployeeForm(),
          ),
    );
  }
}
