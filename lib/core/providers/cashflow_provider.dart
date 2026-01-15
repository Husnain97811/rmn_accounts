import 'dart:math';

import 'package:flutter/material.dart';
import '../../utils/views.dart';

class CashFlowProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedType = 'income';
  String? _selectedCategory;
  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];
  List<CashFlowTransaction> _transactions = [];

  List<CashFlowTransaction> _filteredTransactions = [];

  double _walletBalance = 0.0;
  List<WalletTransaction> _walletTransactions = [];
  bool _showEmployeeFields = false;
  bool _isLoading = false;
  String? _selectedEmployee;
  bool _amountsVisible = false;

  String _searchQuery = '';

  // Getters
  String get selectedType => _selectedType;
  String? get selectedCategory => _selectedCategory;
  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;
  List<CashFlowTransaction> get transactions => _transactions;
  double get walletBalance => _walletBalance;
  List<WalletTransaction> get walletTransactions => _walletTransactions;
  bool get showEmployeeFields => _showEmployeeFields;
  bool get isLoading => _isLoading;
  String? get selectedEmployee => _selectedEmployee;
  bool get amountsVisible => _amountsVisible;

  Future<void> initialize() async {
    await fetchCategories();
  }

  void resetFormState() {
    _selectedType = 'income';
    _selectedCategory = null;
    _showEmployeeFields = false;
    _selectedEmployee = null;
    notifyListeners();
  }

  void clearSelectedEmployee() {
    _selectedEmployee = null;
    notifyListeners();
  }

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense {
    return _transactions
        .where((t) => t.type == 'expense' || t.type == 'wallet expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get maxTransactionAmount =>
      _transactions.isEmpty
          ? 0
          : _transactions.map((t) => t.amount).reduce(max);

  List<ChartData> get categoryData {
    final map = <String, double>{};
    for (var t in _transactions) {
      map.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    final total = totalIncome + totalExpense;
    return map.entries
        .map(
          (e) =>
              ChartData(e.key, e.value / total * 100, _getCategoryColor(e.key)),
        )
        .toList();
  }

  Color _getCategoryColor(String category) {
    final index = _incomeCategories.indexOf(category);
    if (index != -1) return Colors.primaries[index % Colors.primaries.length];
    return Colors.accents[_expenseCategories.indexOf(category) %
        Colors.accents.length];
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('cash_flow_transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      // debugPrint('Raw Supabase response: $response'); // Add this

      _transactions =
          response
              .map((json) {
                try {
                  return CashFlowTransaction.fromJson(json);
                } catch (e) {
                  debugPrint('Error parsing transaction: $e\nJSON: $json');
                  return null;
                }
              })
              .whereType<CashFlowTransaction>()
              .toList();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    String? employeeId,
    int? commission,
    int? incentives,
    String? description,
    required DateTime date, // Add date parameter
  }) async {
    // Fetch old transaction data
    final oldData =
        await _supabase
            .from('cash_flow_transactions')
            .select('type, category, amount, employee_id, employee_commission')
            .eq('id', id)
            .single();
    // Implementation to update transaction in database

    if (oldData['type'] == 'wallet expense') {
      // If the old transaction was a wallet expense, update the wallet balance
      await _supabase
          .from('cash_flow_transactions')
          .update({
            'amount': amount,
            'description': description,
            'employee_id': employeeId,
            'employee_name': _selectedEmployee,
            'date': date.toIso8601String(),
            'employee_commission': commission,
            // 'incentives': incentives,
            // 'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .then((_) async {
            final oldAmount = (oldData['amount'] as num).toDouble();
            _walletBalance += (oldAmount - amount);
            await _supabase
                .from('wallet_balance')
                .update({
                  'balance': _walletBalance,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', 1);
          });
    } else {
      await _supabase
          .from('cash_flow_transactions')
          .update({
            'amount': amount,
            'description': description,
            'employee_id': employeeId,
            'employee_name': _selectedEmployee,
            'date': date.toIso8601String(),
            'employee_commission': commission,
            // 'incentives': incentives,
            // 'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      //if type is wallet balnce then update wallet balnce also
    }

    // Refresh transactions after update
    await loadTransactions();
  }

  Future<void> deleteTransaction(
    int transactionId,
    BuildContext context, {
    CashFlowTransaction? transaction,
  }) async {
    try {
      // If transaction is not provided, find it from the list
      final transactionToDelete =
          transaction ?? _transactions.firstWhere((t) => t.id == transactionId);

      // BEFORE deleting the transaction, handle employee commission deduction if applicable
      if (transactionToDelete.employeeId != null &&
          transactionToDelete.employeeId!.isNotEmpty &&
          transactionToDelete.commission != null &&
          transactionToDelete.commission! > 0) {
        // Fetch current employee data first/
        final employeeResponse = await _supabase
            .from('employers')
            .select('commission_unpaid, unpaid_salary')
            .eq('employee_id', transactionToDelete.employeeId!)
            .single()
            .catchError((e) {
              print('Error fetching employee data: $e');
              return null;
            });

        if (employeeResponse != null) {
          final currentCommission =
              (employeeResponse['commission_unpaid'] as num?)?.toDouble() ??
              0.0;
          final currentUnpaidSalary =
              (employeeResponse['unpaid_salary'] as num?)?.toDouble() ?? 0.0;

          final commissionToDeduct = transactionToDelete.commission!.toDouble();

          // Calculate new values
          final newCommission = currentCommission - commissionToDeduct;
          final newUnpaidSalary = currentUnpaidSalary - commissionToDeduct;

          // Update employee record
          await _supabase
              .from('employers')
              .update({
                'commission_unpaid': newCommission > 0 ? newCommission : 0,
                'unpaid_salary': newUnpaidSalary > 0 ? newUnpaidSalary : 0,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('employee_id', transactionToDelete.employeeId!);
        }
      }

      await _supabase.rpc(
        'delete_transaction_and_adjust_balance',
        params: {'p_transaction_id': transactionId},
      );
      // Remove from local lists
      _transactions.removeWhere((t) => t.id == transactionId);
      _filteredTransactions.removeWhere((t) => t.id == transactionId);

      // Reload data to ensure consistency
      await loadTransactions();
      await loadWalletBalance();
      // if (isWalletExpense) {
      // }

      notifyListeners();

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Transaction deleted successfully',
      );
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error deleting transaction: ${e.toString()}',
      );
      throw e;
    }
  }

  // In CashFlowProvider class
  Future<void> loadWalletBalance() async {
    try {
      // Load wallet balance - always get the first row (id=1)
      final response =
          await _supabase.from('wallet_balance').select().eq('id', 1).single();

      _walletBalance = (response['balance'] as num).toDouble();

      // Load wallet transactions
      final transactionsResponse = await _supabase
          .from('wallet_transactions')
          .select()
          .order('created_at', ascending: false);

      _walletTransactions =
          transactionsResponse
              .map((data) => WalletTransaction.fromMap(data))
              .toList();

      notifyListeners();
    } catch (e) {
      print('Error loading wallet balance: $e');
      // If no balance exists, create one
      await _supabase.from('wallet_balance').insert({'id': 1, 'balance': 0.0});
      _walletBalance = 0.0;
      notifyListeners();
    }
  }

  Future<void> addToWallet(double amount, String description) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Update wallet balance with WHERE clause
      _walletBalance += amount;
      final updateResult = await _supabase
          .from('wallet_balance')
          .update({
            'balance': _walletBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', 1);

      // Add wallet transaction
      // await _supabase.from('wallet_transactions').insert({
      //   'amount': amount,
      //   'description': description,
      //   'type': 'credit',
      //   'created_at': DateTime.now().toIso8601String(),
      // });

      // Reload to ensure consistency
      await loadWalletBalance();

      notifyListeners();
    } catch (e) {
      print('Error adding to wallet: $e');
      // Reload to reset any inconsistent state
      await loadWalletBalance();
      throw Exception('Failed to add amount to wallet: ${e.toString()}');
    }
  }

  Future<void> subtractFromWallet(
    double amount,
    String description,
    String category,
    DateTime date,
  ) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Add to expenses table with provided category
      await _supabase
          .from('cash_flow_transactions')
          .insert({
            'type': 'wallet expense',
            'amount': amount,
            'category': category,
            'description': description,
            'date': date.toIso8601String(),
            'user_id': _supabase.auth.currentUser?.id,
          })
          .then((_) async {
            // After successful insertion, update wallet balance to ensure consistency
            _walletBalance -= amount;
            await _supabase
                .from('wallet_balance')
                .update({
                  'balance': _walletBalance,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', 1);
          });

      // Reload both wallet and transactions
      await loadWalletBalance();
      await loadTransactions();

      notifyListeners();

      print('=== WALLET SUBTRACTION COMPLETED ===');
    } catch (e) {
      print('Error subtracting from wallet: $e');
      // Reload to reset any inconsistent state
      await loadWalletBalance();
      throw e; // Re-throw to show actual error
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('cash_flow_categories')
          .select('name, type')
          .eq('user_id', userId);

      _incomeCategories =
          response
              .where((cat) => cat['type'] == 'income')
              .map((cat) => cat['name'].toString())
              .toList();

      _expenseCategories =
          response
              .where((cat) => cat['type'] == 'expense')
              .map((cat) => cat['name'].toString())
              .toList();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNewCategory(String type, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _supabase.from('cash_flow_categories').insert({
        'name': name,
        'type': type,
        'user_id': userId,
      });

      if (type == 'income') {
        _incomeCategories.add(name);
      } else {
        _expenseCategories.add(name);
      }
      _selectedCategory = name;
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleAmountVisibility() {
    _amountsVisible = !_amountsVisible;
    notifyListeners();
  }

  void setSelectedType(String type) {
    _selectedType = type;
    _selectedCategory = null;
    _showEmployeeFields = false;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setShowEmployeeFields(bool value) {
    _showEmployeeFields = value;
    if (!_showEmployeeFields) {
      _selectedEmployee = null;
    }
    notifyListeners();
  }

  Future<void> verifyEmployee(String employeeId) async {
    if (employeeId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // This assumes you have an employees table
      final response =
          await _supabase
              .from('employers')
              .select('name')
              .eq('employee_id', employeeId)
              .single();

      _selectedEmployee = response['name'];
    } catch (e) {
      _selectedEmployee = null;
      debugPrint('Employee not found: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitTransaction({
    required double amount,
    required String description,
    String? employeeId,
    int? commission,
    int? incentives,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // FIXED: Use employeeId and commission to determine if it's employee commission
      final bool isEmployeeCommission =
          employeeId != null && employeeId.isNotEmpty && commission != null;

      final insertData = {
        'type': _selectedType,
        'amount': amount,
        'category': _selectedCategory!,
        'description': description,
        'date': date.toIso8601String(),
        'user_id': userId,

        // FIXED: Always add these fields when provided (not based on _showEmployeeFields)
        if (employeeId != null && employeeId.isNotEmpty)
          'employee_id': employeeId,
        if (_selectedEmployee != null && _selectedEmployee!.isNotEmpty)
          'employee_name': _selectedEmployee,
        if (commission != null) 'employee_commission': commission,
        // if (incentives != null) 'incentives': incentives,
      };

      debugPrint('Inserting transaction data: $insertData');

      await _supabase.from('cash_flow_transactions').insert(insertData);

      // Update employee records if applicable
      if (isEmployeeCommission) {
        try {
          final res =
              await _supabase
                  .from('employers')
                  .select('unpaid_salary, commission_unpaid, incentives')
                  .eq('employee_id', employeeId)
                  .maybeSingle();

          if (res != null) {
            final currentUnpaid = res['unpaid_salary'] ?? 0;
            final currentCommission = res['commission_unpaid'] ?? 0;
            final currentIncentives = res['incentives'] ?? 0;

            await _supabase
                .from('employers')
                .update({
                  // 'unpaid_salary':
                  //     currentUnpaid +
                  //     (commission ?? 0), // Add commission to unpaid
                  'commission_unpaid':
                      currentCommission +
                      (commission), // Add to total commission
                  // 'is_salary_paid': false,
                  // if (incentives != null)
                  //   'incentives': currentIncentives + incentives,
                })
                .eq('employee_id', employeeId);

            debugPrint('✅ Updated employer record for: $employeeId');
          } else {
            debugPrint('⚠️ No employer record found for employee: $employeeId');
          }
        } catch (e) {
          debugPrint('❌ Error updating employer: $e');
        }
      }

      // Reset form state
      _selectedCategory = null;
      _showEmployeeFields = false;
      _selectedEmployee = null;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Transaction submission error: $e');
      rethrow; // Important: rethrow to see error in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CashFlowTransaction> get filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    return _transactions.where((t) {
      final desc = t.description.toLowerCase();
      final category = t.category.toLowerCase();
      final employee = t.employeeName?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return desc.contains(query) ||
          category.contains(query) ||
          employee.contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<CashFlowTransaction> getFilteredTransactions(
    String timeframe,
    DateTimeRange? dateRange,
    String reportType,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (timeframe) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'yesterday':
        startDate = now.subtract(Duration(days: 1));
        endDate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case 'this_week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'last_week':
        startDate = now.subtract(Duration(days: now.weekday + 6));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'this_month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'last_month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'custom':
        if (dateRange != null) {
          startDate = dateRange.start;
          endDate = dateRange.end;
        } else {
          startDate = DateTime(2000);
        }
        break;
      default:
        startDate = DateTime(2000);
    }

    return transactions.where((t) {
      bool isInDateRange =
          t.date.isAfter(startDate) &&
          t.date.isBefore(endDate.add(Duration(days: 1)));

      if (!isInDateRange) return false;

      // For expense report - ONLY show regular expenses, NOT commissions
      if (reportType == 'Expense') {
        return t.type == 'expense' || t.type == 'wallet expense';
      }
      // For Net Cash Flow report - include both income and regular expenses
      // but NOT commissions as expenses
      else if (reportType == 'Net Cash Flow') {
        return t.type == 'income' || t.type == 'expense';
        // Note: Commissions from income are NOT included here
      }
      // For income report, only show regular income transactions
      else if (reportType == 'Income') {
        return t.type == 'income';
      }
      // For 'all' report type
      else {
        return true;
      }
    }).toList();
  }

  Future<void> deleteCategory(String name, String type) async {
    try {
      await _supabase
          .from('cash_flow_categories')
          .delete()
          .eq('name', name)
          .eq('type', type);

      if (type == 'income') {
        _incomeCategories.remove(name);
      } else {
        _expenseCategories.remove(name);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }
}

class ChartData {
  final String category;
  final double percentage;
  final Color color;

  ChartData(this.category, this.percentage, this.color);
}
