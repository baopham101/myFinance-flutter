import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class FinanceRepository {
  FinanceRepository(this.client);
  final SupabaseClient client;

  Future<List<FinanceCategory>> categories(String? householdId) async {
    dynamic query = client.from('categories').select().filter('deleted_at', 'is', null);
    query = householdId == null ? query.filter('household_id', 'is', null) : query.eq('household_id', householdId);
    query = query.order('type').order('name');
    final rows = await query;
    return (rows as List).map((row) => FinanceCategory.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<List<FinanceWallet>> wallets(String? householdId) async {
    dynamic query = client.from('wallets').select().filter('deleted_at', 'is', null);
    query = householdId == null ? query.filter('household_id', 'is', null) : query.eq('household_id', householdId);
    query = query.order('created_at');
    final rows = await query as List;
    final result = <FinanceWallet>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final walletId = map['id'] as String;
      final response = householdId == null
          ? await client.rpc('wallet_balance', params: {'p_wallet_id': walletId})
          : await client.rpc('wallet_balance', params: {'p_wallet_id': walletId, 'p_household_id': householdId});
      result.add(FinanceWallet.fromJson(map, balance: (response as num?)?.toInt() ?? 0));
    }
    return result;
  }

  Future<List<FinanceTransaction>> transactions(String? householdId) async {
    dynamic query = client.from('transactions').select('''
      *,
      wallet:wallets!transactions_wallet_id_fkey(id,name),
      to_wallet:wallets!transactions_to_wallet_id_fkey(id,name),
      category:categories(id,name,type,color)
    ''').filter('deleted_at', 'is', null);
    query = householdId == null ? query.filter('household_id', 'is', null) : query.eq('household_id', householdId);
    query = query.order('transaction_date', ascending: false).order('created_at', ascending: false).limit(500);
    final rows = await query as List;
    return rows.map((row) => FinanceTransaction.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<void> saveTransaction({
    String? id,
    required TransactionType type,
    required int amount,
    required String walletId,
    String? toWalletId,
    String? categoryId,
    required String description,
    required String transactionDate,
    required String? householdId,
  }) async {
    await client.rpc('save_transaction', params: {
      'p_id': id,
      'p_type': type.name,
      'p_amount': amount,
      'p_wallet_id': walletId,
      'p_category_id': categoryId,
      'p_to_wallet_id': toWalletId,
      'p_description': description,
      'p_transaction_date': transactionDate,
      'p_household_id': householdId,
    });
  }

  Future<void> deleteTransaction(String id) async {
    await client.rpc('soft_delete_transaction', params: {'p_id': id});
  }

  Future<void> saveWallet({String? id, required String name, required WalletType type, int? openingBalance, String? householdId}) async {
    if (id == null) {
      final data = {
        'name': name,
        'type': type.databaseValue,
        'opening_balance': openingBalance ?? 0,
        'currency': 'VND',
        'household_id': householdId,
      };
      await client.from('wallets').insert(data);
    } else {
      await client.from('wallets').update({
        'name': name,
        'type': type.databaseValue,
        'currency': 'VND',
        'household_id': householdId,
      }).eq('id', id);
    }
  }

  Future<void> deleteWallet(String id) async {
    final useCount = await client.from('transactions').select('id').filter('deleted_at', 'is', null).or('wallet_id.eq.$id,to_wallet_id.eq.$id').limit(1);
    if ((useCount as List).isNotEmpty) throw Exception('Ví đã có giao dịch nên không thể xóa.');
    await client.from('wallets').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  Future<void> saveCategory({String? id, required String name, required String type, required String color, String? householdId}) async {
    final values = {'name': name.trim(), 'type': type, 'color': color};
    if (id == null) {
      await client.from('categories').insert({...values, 'household_id': householdId});
    } else {
      await client.from('categories').update(values).eq('id', id);
    }
  }

  Future<void> deleteCategory(String id) async {
    await client.from('categories').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  Future<List<HouseholdInfo>> households() async {
    final rows = await client.from('household_members').select('role, household:households(id,name,owner_id,created_at)').order('joined_at');
    return (rows as List).map((item) {
      final row = Map<String, dynamic>.from(item as Map);
      final nested = row['household'];
      if (nested == null) return null;
      final household = nested is Map<String, dynamic> ? nested : Map<String, dynamic>.from((nested as List).first as Map);
      return HouseholdInfo.fromJson(household, role: row['role'] as String?);
    }).whereType<HouseholdInfo>().toList();
  }

  Future<HouseholdInfo> createHousehold(String name) async {
    final data = await client.rpc('create_household', params: {'p_name': name.trim()});
    return HouseholdInfo.fromJson(Map<String, dynamic>.from(data as Map), role: 'owner');
  }

  Future<List<HouseholdMemberInfo>> householdMembers(String householdId) async {
    final rows = await client.from('household_members').select('user_id,role,joined_at').eq('household_id', householdId).order('joined_at');
    return (rows as List).map((row) => HouseholdMemberInfo.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<List<HouseholdInvite>> householdInvites(String householdId) async {
    final rows = await client.from('household_invitations').select().eq('household_id', householdId).order('created_at', ascending: false);
    return (rows as List).map((row) => HouseholdInvite.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<List<HouseholdInvite>> pendingInvites() async {
    final email = client.auth.currentUser?.email;
    if (email == null) return [];
    final rows = await client.from('household_invitations').select('*, household:households(id,name)').ilike('email', email).eq('status', 'pending').order('created_at', ascending: false);
    return (rows as List).map((row) => HouseholdInvite.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<void> inviteMember(String householdId, String email, String role) async {
    await client.rpc('invite_household_member', params: {'p_household_id': householdId, 'p_email': email.trim(), 'p_role': role});
  }

  Future<void> acceptInvite(String invitationId) async {
    await client.rpc('accept_household_invitation', params: {'p_invitation_id': invitationId});
  }

  Future<void> leaveHousehold(String householdId) async {
    await client.rpc('leave_household', params: {'p_household_id': householdId});
  }

  Future<List<FinanceBudget>> budgets(String? householdId) async {
    dynamic query = client.from('budgets').select('*, category:categories(id,name,color)').filter('deleted_at', 'is', null);
    query = householdId == null ? query.filter('household_id', 'is', null) : query.eq('household_id', householdId);
    query = query.order('period_start', ascending: false);
    final rows = await query as List;
    final result = <FinanceBudget>[];
    for (final item in rows) {
      final map = Map<String, dynamic>.from(item as Map);
      final spent = await client.rpc('budget_spent', params: {'p_budget_id': map['id']});
      result.add(FinanceBudget.fromJson(map, spent: (spent as num?)?.toInt() ?? 0));
    }
    return result;
  }

  Future<void> saveBudget({String? id, required String categoryId, required int limitAmount, required String start, required String end, required String? householdId}) async {
    final data = {
      'category_id': categoryId,
      'limit_amount': limitAmount,
      'period_start': start,
      'period_end': end,
      'household_id': householdId,
    };
    if (id == null) {
      await client.from('budgets').insert(data);
    } else {
      await client.from('budgets').update(data).eq('id', id);
    }
  }

  Future<void> deleteBudget(String id) async {
    await client.from('budgets').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }
}
