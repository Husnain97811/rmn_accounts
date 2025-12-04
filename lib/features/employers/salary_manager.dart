import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalaryManager {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> initializeMonthlySalaries() async {
    await _supabase.rpc('initialize_monthly_salaries');
  }

  Future<void> processSalaryPayment({
    required String employeeId,
    required double amount,
    required String categoryId,
    required DateTime monthYear,
  }) async {
    await _supabase.from('paid_salaries').insert({
      'employee_id': employeeId,
      'amount': amount,
      'category_id': categoryId,
      'month_year': monthYear.toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getSalaryCategories() async {
    final response = await _supabase
        .from('cash_flow_categories')
        .select()
        .or(
          'name.eq.Monthly Salary,name.eq.Salary Commission,name.eq.Salary Advance',
        );

    return {
      'salary': response.firstWhere((c) => c['name'] == 'Monthly Salary'),
      'commission': response.firstWhere(
        (c) => c['name'] == 'Salary Commission',
      ),
      'advance': response.firstWhere((c) => c['name'] == 'Salary Advance'),
    };
  }
}
