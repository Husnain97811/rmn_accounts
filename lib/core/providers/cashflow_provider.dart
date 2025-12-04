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

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

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
    // Implementation to update transaction in database
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

    // Refresh transactions after update
    await loadTransactions();
  }

  // Future<void> deleteTransaction(
  //   String id,
  //   BuildContext context, {
  //   CashFlowTransaction? transaction, // Make this optional
  // }) async {
  //   try {
  //     await _supabase.from('cash_flow_transactions').delete().eq('id', id);
  //     _transactions.removeWhere((t) => t.id == id);
  //     notifyListeners();
  //     SupabaseExceptionHandler.showSuccessSnackbar(
  //       context,
  //       'Successfully Deleted',
  //     );
  //   } catch (e) {
  //     SupabaseExceptionHandler.showErrorSnackbar(
  //       context,
  //       'Something went wrong $e',
  //     );
  //     // rethrow;
  //   }
  // }

  Future<void> deleteTransaction(
    int transactionId,
    BuildContext context, {
    CashFlowTransaction? transaction,
  }) async {
    try {
      // If transaction is not provided, find it from the list
      final transactionToDelete =
          transaction ?? _transactions.firstWhere((t) => t.id == transactionId);

      // Check if this is a wallet expense
      final isWalletExpense =
          transactionToDelete.type == 'expense' &&
          transactionToDelete.category.toLowerCase() == 'wallet';

      if (isWalletExpense) {
        // Method 1: Try to find by direct amount and description matching (more reliable)
        final walletTransactions = await _supabase
            .from('wallet_transactions')
            .select()
            .eq('amount', transactionToDelete.amount)
            .eq('type', 'debit')
            .eq('description', transactionToDelete.description)
            .order('created_at', ascending: false)
            .limit(1);

        if (walletTransactions.isNotEmpty) {
          final walletTransaction = walletTransactions.first;
          final walletTransactionId = walletTransaction['id'] as int;

          await _supabase
              .from('wallet_transactions')
              .delete()
              .eq('id', walletTransactionId);

          // Add the amount back to wallet balance
          _walletBalance += transactionToDelete.amount;
          await _supabase
              .from('wallet_balance')
              .update({
                'balance': _walletBalance,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', 1);
        } else {
          // Even if no wallet transaction found, we should still update the balance
          // because the expense was subtracted from wallet
          _walletBalance += transactionToDelete.amount;
          await _supabase
              .from('wallet_balance')
              .update({
                'balance': _walletBalance,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', 1);
        }
      }

      // Delete the main transaction
      await _supabase
          .from('cash_flow_transactions')
          .delete()
          .eq('id', transactionId);

      // Remove from local lists
      _transactions.removeWhere((t) => t.id == transactionId);
      _filteredTransactions.removeWhere((t) => t.id == transactionId);

      // Reload data to ensure consistency
      await loadTransactions();
      if (isWalletExpense) {
        await loadWalletBalance();
      }

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
      await _supabase.from('wallet_transactions').insert({
        'amount': amount,
        'description': description,
        'type': 'credit',
        'created_at': DateTime.now().toIso8601String(),
      });

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

  Future<void> subtractFromWallet(double amount, String description) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      if (_walletBalance < amount) {
        throw Exception(
          'Insufficient wallet balance. Available: $_walletBalance',
        );
      }

      // Update wallet balance
      _walletBalance -= amount;
      await _supabase
          .from('wallet_balance')
          .update({
            'balance': _walletBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', 1);

      print('Creating wallet transaction...');
      // Add wallet transaction first and get the ID
      final walletResponse =
          await _supabase.from('wallet_transactions').insert({
            'amount': amount,
            'description': description.isEmpty ? 'Wallet Expense' : description,
            'type': 'debit',
            'created_at': DateTime.now().toIso8601String(),
          }).select();

      final walletTransactionId = walletResponse.first['id'] as int;
      print('Wallet transaction created with ID: $walletTransactionId');

      // Add to expenses table with category "wallet"
      await _supabase.from('cash_flow_transactions').insert({
        'type': 'expense',
        'amount': amount,
        'category': 'wallet',
        'description': description.isEmpty ? 'Wallet Expense' : description,
        'date': DateTime.now().toIso8601String(),
        'user_id': _supabase.auth.currentUser?.id,
        'wallet_transaction_id': walletTransactionId, // Store the link
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
    required DateTime date, // Add date parameter
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final insertData = {
        'type': _selectedType,
        'amount': amount,
        'category': _selectedCategory!,
        'description': description,
        'date': date.toIso8601String(),
        'user_id': userId,
        if (_showEmployeeFields) ...{
          'employee_id': employeeId,
          'employee_name': _selectedEmployee,
          'employee_commission': commission,
        },
      };

      await _supabase.from('cash_flow_transactions').insert(insertData);

      // Update employee records if applicable
      if (_showEmployeeFields && employeeId != null && commission != null) {
        try {
          final res =
              await _supabase
                  .from('employers')
                  .select('unpaid_salary, commission')
                  .eq('employee_id', employeeId)
                  .maybeSingle();

          if (res != null) {
            final currentUnpaid = res['unpaid_salary'] ?? 0;
            final currentCommission = res['commission'] ?? 0;
            final currentIncentives = res['incentives'] ?? 0;

            await _supabase
                .from('employers')
                .update({
                  'is_salary_paid': false,
                  'incentives': currentIncentives + incentives!,
                })
                .eq('employee_id', employeeId);
          } else {
            debugPrint('No employer record found for employee: $employeeId');
          }
        } catch (e) {
          debugPrint('Error updating employer: $e');
        }
      }

      // Reset form state
      _selectedCategory = null;
      _showEmployeeFields = false;
      _selectedEmployee = null;
    } catch (e) {
      debugPrint('Transaction submission error: $e');
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
      return t.date.isAfter(startDate) &&
          t.date.isBefore(endDate.add(Duration(days: 1))) &&
          (reportType == 'all' ||
              (reportType == 'Income' && t.type == 'income') ||
              (reportType == 'Expense' && t.type == 'expense') ||
              reportType == 'Net Cash Flow');
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
