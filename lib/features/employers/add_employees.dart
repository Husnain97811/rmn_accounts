import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import '../../utils/views.dart';

class AddEmployeeForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  final Map<String, dynamic>? employee;

  const AddEmployeeForm({super.key, this.employee, this.onSuccess});

  @override
  State<AddEmployeeForm> createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends State<AddEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _hraController = TextEditingController();
  final _medicalAllowanceController = TextEditingController();
  final _conveyanceAllowanceController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _hireDateController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  String? _imageUrl;
  File? _selectedImage;
  DateTime? _selectedDate;
  DateTime? _selectedDateofBirth;

  // add init state here
  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!['name'] ?? '';
      _emailController.text = widget.employee!['email'] ?? '';
      _phoneController.text = widget.employee!['phone'] ?? '';
      _salaryController.text = widget.employee!['salary']?.toString() ?? '';
      _hraController.text = widget.employee!['hra_amount']?.toString() ?? '';
      _medicalAllowanceController.text =
          widget.employee!['medical_allowance']?.toString() ?? '';
      _conveyanceAllowanceController.text =
          widget.employee!['conveyance_allowance']?.toString() ?? '';
      _imageUrl = widget.employee!['image_url'];
      _hireDateController.text =
          widget.employee!['hire_date']?.toString() ?? '';
      _departmentController.text = widget.employee!['department'] ?? '';
      _designationController.text = widget.employee!['designation'] ?? '';
      _employeeIdController.text = widget.employee!['employee_id'] ?? '';
      _cnicController.text = widget.employee!['cnic'] ?? '';
      _addressController.text = widget.employee!['address'] ?? '';
      _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(
        DateTime.parse(widget.employee!['date_of_birth'].toString() ?? ''),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hireDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  // In your AddEmployeeForm widget
  Future<void> _selectDateofBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateofBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Can't select future date for birth date
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.blueGrey, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateofBirth) {
      setState(() {
        _selectedDateofBirth = picked;
        _dateOfBirthController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.startLoading();
    final currentUser = _supabase.auth.currentUser;
    String editorName = 'Unknown';

    if (currentUser != null) {
      try {
        //checking current username and updarting it
        final profile =
            await _supabase
                .from('profiles')
                .select('name')
                .eq('user_id', currentUser.id)
                .single();

        editorName = profile['name'] ?? currentUser.email ?? 'Unknown';

        // now save data or update data
        if (widget.employee != null) {
          // Update existing employee
          await _supabase
              .from('employers')
              .update({
                'name': _capitalizeFirstLetter(_nameController.text),
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
                'salary': double.tryParse(_salaryController.text) ?? 0,
                'hra_amount': double.tryParse(_hraController.text) ?? 0,
                'medical_allowance':
                    double.tryParse(_medicalAllowanceController.text) ?? 0,
                'conveyance_allowance':
                    double.tryParse(_conveyanceAllowanceController.text) ?? 0,
                'image_url': _imageUrl,
                // 'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'edited_by': editorName,
                // 'hire_date':
                //     _selectedDate?.toIso8601String() ??
                //     DateTime.now().toIso8601String(),
                'department': _departmentController.text.trim().toLowerCase(),
                'designation': _capitalizeFirstLetter(
                  _designationController.text,
                ),
                'employee_id': _employeeIdController.text.trim().toLowerCase(),
                'cnic': _cnicController.text.trim(),
                'address': _addressController.text.trim(),
                // 'date_of_birth':
                //     _selectedDateofBirth?.toIso8601String() ??
                //     DateTime.now().toIso8601String(),
              })
              .eq('id', widget.employee!['id']);
        } else {
          await _supabase.from('employers').insert({
            'name': _capitalizeFirstLetter(_nameController.text),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'salary': double.tryParse(_salaryController.text) ?? 0,
            'hra_amount': double.tryParse(_hraController.text) ?? 0,
            'medical_allowance':
                double.tryParse(_medicalAllowanceController.text) ?? 0,
            'conveyance_allowance':
                double.tryParse(_conveyanceAllowanceController.text) ?? 0,
            'image_url': _imageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': null,
            'hire_date':
                _selectedDate?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'department': _departmentController.text..trim().toLowerCase(),
            'designation': _capitalizeFirstLetter(_designationController.text),
            'employee_id': _employeeIdController.text.trim().toLowerCase(),
            'cnic': _cnicController.text.trim(),
            'address': _addressController.text.trim(),
            'date_of_birth':
                _selectedDateofBirth?.toIso8601String() ??
                DateTime.now().toIso8601String(),
          });
        }

        if (mounted) {
          loadingProvider.stopLoading();
          SupabaseExceptionHandler.showSuccessSnackbar(
            context,
            'Added Successfully',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        loadingProvider.stopLoading();
        if (mounted) {
          SupabaseExceptionHandler.showErrorSnackbar(
            context,
            'Error adding employee: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          loadingProvider.stopLoading();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _hraController.dispose();
    _medicalAllowanceController.dispose();
    _conveyanceAllowanceController.dispose();
    _departmentController.dispose();
    _hireDateController.dispose();
    _designationController.dispose();
    _employeeIdController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 1,
        // bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: LoadingOverlay(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Column(
                children: [
                  Text(
                    'Add New Employee',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3.h),

                  CustomTextFormField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _employeeIdController,
                    labelText: 'Employee ID',
                    prefixIcon: Icons.confirmation_number_sharp,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _departmentController,
                    labelText: 'Department',
                    prefixIcon: Icons.work,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _designationController,
                    labelText: 'Designation',
                    prefixIcon: Icons.work,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _cnicController,
                    labelText: 'Cnic',
                    prefixIcon: Icons.contact_mail_outlined,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _salaryController,
                    labelText: 'Monthly Salary',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required field';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _hraController,
                    labelText: 'HRA',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required field';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _medicalAllowanceController,
                    labelText: 'Medical Allowance',
                    prefixIcon: Icons.medical_information,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required field';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _conveyanceAllowanceController,
                    labelText: 'Conveyance Allowance',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required field';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _hireDateController,
                    labelText: 'Hire Date',
                    prefixIcon: Icons.calendar_today,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_month),
                      onPressed: () => _selectDate(context),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _addressController,
                    labelText: 'Address',
                    prefixIcon: Icons.maps_home_work_outlined,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  SizedBox(height: 1.h),
                  CustomTextFormField(
                    controller: _dateOfBirthController,
                    labelText: 'Date of Birth',
                    prefixIcon: Icons.calendar_month,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _selectDateofBirth(context),
                    ),
                    readOnly: true,
                    onTap: () => _selectDateofBirth(context), // This is crucial
                    validator:
                        (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Add Employee',
                      style: TextStyle(fontSize: 12.sp),
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
}
