typedef JsonMap = Map<String, dynamic>;

enum TransactionType { expense, income, transfer }

enum WalletType { cash, bank, card, eWallet, savings }

extension WalletTypeDatabaseValue on WalletType {
  String get databaseValue => this == WalletType.eWallet ? 'e_wallet' : name;
}

enum HouseholdRole { owner, admin, member }

TransactionType transactionTypeFrom(String value) => TransactionType.values.firstWhere((item) => item.name == value);
WalletType walletTypeFrom(String value) => value == 'e_wallet' ? WalletType.eWallet : WalletType.values.firstWhere((item) => item.name == value, orElse: () => WalletType.cash);
HouseholdRole householdRoleFrom(String value) => HouseholdRole.values.firstWhere((item) => item.name == value, orElse: () => HouseholdRole.member);

class FinanceCategory {
  const FinanceCategory({required this.id, required this.name, required this.type, required this.icon, required this.color});
  final String id;
  final String name;
  final String type;
  final String icon;
  final String color;
  factory FinanceCategory.fromJson(JsonMap json) => FinanceCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        icon: json['icon'] as String? ?? 'Circle',
        color: json['color'] as String? ?? '#16845b',
      );
}

class FinanceWallet {
  const FinanceWallet({required this.id, required this.name, required this.type, required this.openingBalance, required this.balance, this.householdId});
  final String id;
  final String name;
  final WalletType type;
  final int openingBalance;
  final int balance;
  final String? householdId;
  factory FinanceWallet.fromJson(JsonMap json, {int? balance}) => FinanceWallet(
        id: json['id'] as String,
        name: json['name'] as String,
        type: walletTypeFrom(json['type'] as String? ?? 'cash'),
        openingBalance: (json['opening_balance'] as num?)?.toInt() ?? 0,
        balance: balance ?? (json['opening_balance'] as num?)?.toInt() ?? 0,
        householdId: json['household_id'] as String?,
      );
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.walletId,
    required this.transactionDate,
    required this.description,
    this.toWalletId,
    this.categoryId,
    this.walletName,
    this.toWalletName,
    this.categoryName,
    this.categoryColor,
  });
  final String id;
  final TransactionType type;
  final int amount;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final String transactionDate;
  final String description;
  final String? walletName;
  final String? toWalletName;
  final String? categoryName;
  final String? categoryColor;

  factory FinanceTransaction.fromJson(JsonMap json) {
    final wallet = _nestedMap(json['wallet']);
    final toWallet = _nestedMap(json['to_wallet']);
    final category = _nestedMap(json['category']);
    return FinanceTransaction(
      id: json['id'] as String,
      type: transactionTypeFrom(json['type'] as String),
      amount: (json['amount'] as num).toInt(),
      walletId: json['wallet_id'] as String,
      toWalletId: json['to_wallet_id'] as String?,
      categoryId: json['category_id'] as String?,
      transactionDate: (json['transaction_date'] as String).substring(0, 10),
      description: json['description'] as String? ?? '',
      walletName: wallet?['name'] as String?,
      toWalletName: toWallet?['name'] as String?,
      categoryName: category?['name'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }
}

class HouseholdInfo {
  const HouseholdInfo({required this.id, required this.name, required this.role, this.ownerId = ''});
  final String id;
  final String name;
  final HouseholdRole role;
  final String ownerId;
  factory HouseholdInfo.fromJson(JsonMap json, {String? role}) => HouseholdInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        role: householdRoleFrom(role ?? json['role'] as String? ?? 'member'),
        ownerId: json['owner_id'] as String? ?? '',
      );
}

class HouseholdInvite {
  const HouseholdInvite({required this.id, required this.householdId, required this.email, required this.role, required this.status, this.householdName});
  final String id;
  final String householdId;
  final String email;
  final String role;
  final String status;
  final String? householdName;
  factory HouseholdInvite.fromJson(JsonMap json) {
    final household = _nestedMap(json['household']);
    return HouseholdInvite(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'pending',
      householdName: household?['name'] as String?,
    );
  }
}

class HouseholdMemberInfo {
  const HouseholdMemberInfo({required this.userId, required this.role, required this.joinedAt});
  final String userId;
  final String role;
  final String joinedAt;
  factory HouseholdMemberInfo.fromJson(JsonMap json) => HouseholdMemberInfo(
        userId: json['user_id'] as String,
        role: json['role'] as String,
        joinedAt: json['joined_at'] as String,
      );
}

class FinanceBudget {
  const FinanceBudget({required this.id, required this.categoryId, required this.limitAmount, required this.periodStart, required this.periodEnd, required this.spent, required this.categoryName, required this.categoryColor});
  final String id;
  final String categoryId;
  final int limitAmount;
  final String periodStart;
  final String periodEnd;
  final int spent;
  final String categoryName;
  final String categoryColor;
  factory FinanceBudget.fromJson(JsonMap json, {int spent = 0}) {
    final category = _nestedMap(json['category']);
    return FinanceBudget(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      limitAmount: (json['limit_amount'] as num).toInt(),
      periodStart: (json['period_start'] as String).substring(0, 10),
      periodEnd: (json['period_end'] as String).substring(0, 10),
      spent: spent,
      categoryName: category?['name'] as String? ?? 'Danh mục đã xóa',
      categoryColor: category?['color'] as String? ?? '#94a3b8',
    );
  }
}

JsonMap? _nestedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  return null;
}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
