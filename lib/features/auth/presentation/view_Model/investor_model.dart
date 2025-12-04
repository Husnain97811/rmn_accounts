import 'package:intl/intl.dart';
import 'package:rmn_accounts/features/auth/presentation/view_Model/profit_schedule.dart';
import 'package:uuid/uuid.dart';

class Investor {
  final String id;
  final String name;
  final String investorIdCode;
  final String email;
  final String phone;
  final String cnic;
  final String address;
  final double initialInvestmentAmount;
  final double returnAmount;
  final double balanceAmount;
  final String profitCalculationType;
  final int profitDuration;
  final double profitValue;
  final double unpaidProfitBalance;
  final bool isProfitPaidForCycle;
  final String status;
  DateTime? expireDate;
  final DateTime investmentDate;
  final DateTime endDate;
  final String? profileImage;

  final Map<String, bool> paidInstallments;
  final int totalInstallments;

  final String createdBy;
  final String editedBy;
  final DateTime createdAt;
  final int? timeDuration;

  final DateTime updatedAt;
  final List<ProfitSchedule> profitSchedules;
  final DateTime? lastProfitAccrualDate; // Add this field
  double? paidCommission;
  double? unpaidCommission;

  Investor({
    this.timeDuration,
    required this.id,
    required this.name,
    required this.investorIdCode,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.initialInvestmentAmount,
    this.returnAmount = 0.0,
    this.balanceAmount = 0.0,
    required this.profitCalculationType,
    required this.profitDuration,
    required this.profitValue,
    required this.unpaidProfitBalance,
    required this.isProfitPaidForCycle,
    required this.status,
    this.expireDate,
    required this.investmentDate,
    required this.endDate,
    required this.createdBy,
    required this.editedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.profitSchedules,
    this.profileImage,
    this.lastProfitAccrualDate, // Added
    this.paidCommission,
    this.unpaidCommission,
    required this.paidInstallments,
    required this.totalInstallments,
  });

  factory Investor.fromJson(Map<String, dynamic> json) {
    return Investor(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      investorIdCode: json['investor_id_code'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      cnic: json['cnic'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      initialInvestmentAmount:
          (json['initial_investment_amount'] as num?)?.toDouble() ?? 0.0,
      returnAmount: (json['return_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      profitCalculationType:
          json['profit_calculation_type'] as String? ?? 'fixed',
      profitDuration: (json['profit_duration'] as num?)?.toInt() ?? 1,
      timeDuration: (json['time_duration'] as num?)?.toInt() ?? 6,
      profitValue: (json['profit_value'] as num?)?.toDouble() ?? 0.0,
      unpaidProfitBalance:
          (json['unpaid_profit_balance'] as num?)?.toDouble() ?? 0.0,
      isProfitPaidForCycle: json['is_profit_paid_for_cycle'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      expireDate:
          json['expire_date'] != null
              ? DateTime.parse(json['expire_date'] as String)
              : null,
      investmentDate:
          json['investment_date'] != null
              ? DateTime.parse(json['investment_date'] as String)
              : DateTime.now(),
      endDate:
          json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : DateTime.now(),
      createdBy: json['created_by'] as String? ?? 'system',
      editedBy: json['edited_by'] as String? ?? 'system',
      paidInstallments: Map<String, bool>.from(json['paid_installments'] ?? {}),
      totalInstallments: json['total_installments'] ?? 0,
      profileImage: json['profile_picture_url'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
      profitSchedules:
          (json['profit_schedules'] as List<dynamic>?)
              ?.map(
                (e) =>
                    e == null
                        ? ProfitSchedule.fromJson({})
                        : ProfitSchedule.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      lastProfitAccrualDate:
          json['last_profit_accrual_date'] != null
              ? DateTime.parse(json['last_profit_accrual_date'] as String)
              : null,
      paidCommission: (json['paid_commission'] as num?)?.toDouble() ?? 0.0,
      unpaidCommission: (json['unpaid_commission'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'investor_id_code': investorIdCode,
    'email': email,
    'phone': phone,
    'cnic': cnic,
    'address': address,
    'initial_investment_amount': initialInvestmentAmount,
    'return_amount': returnAmount,
    'balance_amount': balanceAmount,
    // 'profit_calculation_type': profitCalculationType,
    'investment_date': DateFormat('yyyy-MM-dd').format(investmentDate),
    'end_date':
        endDate != null
            ? DateFormat('yyyy-MM-dd').format(endDate!)
            : null, // Handle null if nullable
    'profit_duration': profitDuration,
    'time_duration': timeDuration,
    'profit_value': profitValue,
    'unpaid_profit_balance': unpaidProfitBalance,
    'is_profit_paid_for_cycle': isProfitPaidForCycle,
    'status': status,
    "expire_date": null,
    'profile_picture_url': profileImage,

    'created_by': createdBy,
    'edited_by': editedBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Investor copyWith({
    String? name,
    String? investorIdCode,
    String? email,
    String? phone,
    String? cnic,
    String? address,
    double? initialInvestmentAmount,
    double? returnAmount,
    double? balanceAmount,
    String? profitCalculationType,
    int? profitDuration,
    int? timeDuration,
    double? profitValue,
    double? unpaidProfitBalance,
    bool? isProfitPaidForCycle,
    String? status,
    String? profileImage,
    DateTime? expireDate,
    DateTime? investmentDate,
    DateTime? endDate,
    String? editedBy,
    DateTime? updatedAt,
  }) => Investor(
    id: id,
    name: name ?? this.name,
    investorIdCode: investorIdCode ?? this.investorIdCode,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    cnic: cnic ?? this.cnic,
    address: address ?? this.address,
    initialInvestmentAmount:
        initialInvestmentAmount ?? this.initialInvestmentAmount,
    returnAmount: returnAmount ?? this.returnAmount,
    balanceAmount: balanceAmount ?? this.balanceAmount,
    profitCalculationType: profitCalculationType ?? this.profitCalculationType,
    profitDuration: profitDuration ?? this.profitDuration,
    timeDuration: timeDuration ?? this.timeDuration,
    paidInstallments: paidInstallments,
    totalInstallments: totalInstallments,
    profitValue: profitValue ?? this.profitValue,
    unpaidProfitBalance: unpaidProfitBalance ?? this.unpaidProfitBalance,
    isProfitPaidForCycle: isProfitPaidForCycle ?? this.isProfitPaidForCycle,
    status: status ?? this.status,
    expireDate: expireDate ?? this.expireDate,
    investmentDate: investmentDate ?? this.investmentDate,
    endDate: endDate ?? this.endDate,
    createdBy: createdBy,
    profileImage: profileImage ?? this.profileImage,
    editedBy: editedBy ?? this.editedBy,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    profitSchedules: profitSchedules,
    paidCommission: paidCommission ?? this.paidCommission,
    unpaidCommission: unpaidCommission ?? this.unpaidCommission,
  );

  DateTime? get nextAccrualDate {
    if (profitSchedules.isEmpty) return null;
    final lastAccrual = lastProfitAccrualDate ?? investmentDate;
    // final currentSchedule = profitSchedules.lastWhere(
    // (s) => s.isActiveSchedule,
    // orElse: () => profitSchedules.last,
    // );
    return DateTime(
      lastAccrual.year,
      // lastAccrual.month + currentSchedule.profitIntervalMonths,
      lastAccrual.day,
    );
  }
}
