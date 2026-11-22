import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/finance_repository.dart';
import '../data/models.dart';
import '../widgets/transaction_editor_sheet.dart';
import 'account_screen.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'household_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';
import 'wallets_screen.dart';

class FinanceAppShell extends StatefulWidget {
  const FinanceAppShell({required this.themeMode, required this.onThemeChanged, super.key});
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<FinanceAppShell> createState() => _FinanceAppShellState();
}

class _FinanceAppShellState extends State<FinanceAppShell> {
  final _repository = FinanceRepository(Supabase.instance.client);
  final _transactionsKey = GlobalKey<TransactionsScreenState>();
  List<HouseholdInfo> _households = [];
  String? _householdId;
  String _page = 'overview';
  int _revision = 0;
  bool _loadingHouseholds = true;
  String? _householdError;

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
    try {
      final rows = await _repository.households();
      if (!mounted) return;
      setState(() { _households = rows; _loadingHouseholds = false; _householdError = null; if (_householdId != null && !rows.any((item) => item.id == _householdId)) _householdId = null; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _householdError = _friendlyError(error); _loadingHouseholds = false; });
    }
  }

  void _navigate(String page) => setState(() => _page = page);

  Future<void> _quickAdd() async {
    late final List<Object?> values;
    try {
      values = await Future.wait([_repository.wallets(_householdId), _repository.categories(_householdId)]);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      return;
    }
    final wallets = values[0] as List<FinanceWallet>;
    if (!mounted) return;
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy tạo ví trước khi thêm giao dịch.')));
      _navigate('wallets');
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => TransactionEditorSheet(repository: _repository, wallets: wallets, categories: values[1] as List<FinanceCategory>, householdId: _householdId),
    );
    if (saved == true && mounted) {
      setState(() => _revision++);
      // Refresh the transactions screen future so the just-saved transaction appears
      _loadHouseholds();
      _transactionsKey.currentState?.refresh();
    }
  }

  int get _tabIndex => switch (_page) {
        'overview' => 0,
        'transactions' => 1,
        'wallets' => 2,
        'budgets' => 3,
        _ => 4,
      };

  Widget _pageBody() {
    final key = ValueKey('${_page}_${_householdId ?? 'personal'}_$_revision');
    return switch (_page) {
      'overview' => DashboardScreen(key: key, repository: _repository, householdId: _householdId, onNavigate: _navigate, onAddTransaction: _quickAdd),
      'transactions' => TransactionsScreen(key: _transactionsKey, repository: _repository, householdId: _householdId),
      'wallets' => WalletsScreen(key: key, repository: _repository, householdId: _householdId),
      'budgets' => BudgetsScreen(key: key, repository: _repository, householdId: _householdId),
      'categories' => CategoriesScreen(key: key, repository: _repository, householdId: _householdId),
      'reports' => ReportsScreen(key: key, repository: _repository, householdId: _householdId),
      'household' => HouseholdScreen(key: key, repository: _repository, activeHouseholdId: _householdId, onChanged: _loadHouseholds),
      'settings' => SettingsScreen(key: key, themeMode: widget.themeMode, onThemeChanged: widget.onThemeChanged),
      _ => AccountScreen(key: key, onNavigate: _navigate),
    };
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).colorScheme.primary, size: 23),
          const SizedBox(width: 9),
          const Text('MyFinance', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          if (_householdError != null)
            IconButton(tooltip: 'Không tải được nhóm', onPressed: _loadHouseholds, icon: const Icon(Icons.sync_problem_outlined)),
          if (_loadingHouseholds)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _householdId ?? '',
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.expand_more_rounded),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Cá nhân')),
                    ..._households.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (value) {
                    final selected = _households.where((item) => item.id == value).firstOrNull;
                    setState(() { _householdId = selected?.id; });
                  },
                ),
              ),
            ),
        ],
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Row(children: [
        if (wide)
          NavigationRail(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => _navigate(['overview', 'transactions', 'wallets', 'budgets', 'account'][index]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: Text('Tổng quan')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: Text('Giao dịch')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: Text('Ví')),
              NavigationRailDestination(icon: Icon(Icons.pie_chart_outline_rounded), selectedIcon: Icon(Icons.pie_chart_rounded), label: Text('Ngân sách')),
              NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: Text('Tài khoản')),
            ],
          ),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980), child: _pageBody()))),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => _navigate(['overview', 'transactions', 'wallets', 'budgets', 'account'][index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Giao dịch'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Ví'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded), selectedIcon: Icon(Icons.pie_chart_rounded), label: 'Ngân sách'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Tài khoản'),
        ],
      ),

    );
  }
}

String _friendlyError(Object error) {
  if (error is PostgrestException) return error.message;
  if (error is AuthException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}
