import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyFinanceApp());
}

const _green = Color(0xFF147D64);
const _ink = Color(0xFF172B27);
const _muted = Color(0xFF788782);
const _canvas = Color(0xFFF5F7F6);

class FinanceTransaction {
  FinanceTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.note = '',
  });

  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime date;
  final bool isIncome;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
        'note': note,
      };

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) =>
      FinanceTransaction(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
        isIncome: json['isIncome'] as bool,
        note: json['note'] as String? ?? '',
      );
}

class MyFinanceApp extends StatefulWidget {
  const MyFinanceApp({super.key});

  @override
  State<MyFinanceApp> createState() => _MyFinanceAppState();
}

class _MyFinanceAppState extends State<MyFinanceApp> {
  List<FinanceTransaction> _transactions = [];
  bool _isDark = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('transactions');
    final dark = prefs.getBool('dark_mode') ?? false;
    if (!mounted) return;
    setState(() {
      _transactions = raw == null
          ? _sampleTransactions()
          : (jsonDecode(raw) as List<dynamic>)
              .map((e) => FinanceTransaction.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList();
      _isDark = dark;
      _loaded = true;
    });
    if (raw == null) _save();
  }

  List<FinanceTransaction> _sampleTransactions() {
    final now = DateTime.now();
    return [
      FinanceTransaction(
        id: 'seed-1',
        title: 'Lương tháng',
        category: 'Lương',
        amount: 18000000,
        date: DateTime(now.year, now.month, 1),
        isIncome: true,
      ),
      FinanceTransaction(
        id: 'seed-2',
        title: 'Đi chợ cuối tuần',
        category: 'Ăn uống',
        amount: 420000,
        date: DateTime(now.year, now.month, 3),
        isIncome: false,
      ),
      FinanceTransaction(
        id: 'seed-3',
        title: 'Tiền điện',
        category: 'Hóa đơn',
        amount: 760000,
        date: DateTime(now.year, now.month, 5),
        isIncome: false,
      ),
      FinanceTransaction(
        id: 'seed-4',
        title: 'Cà phê',
        category: 'Ăn uống',
        amount: 65000,
        date: DateTime(now.year, now.month, 7),
        isIncome: false,
      ),
      FinanceTransaction(
        id: 'seed-5',
        title: 'Làm thêm',
        category: 'Thu nhập khác',
        amount: 1200000,
        date: DateTime(now.year, now.month, 9),
        isIncome: true,
      ),
    ];
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'transactions',
      jsonEncode(_transactions.map((item) => item.toJson()).toList()),
    );
    await prefs.setBool('dark_mode', _isDark);
  }

  Future<void> _openEditor({FinanceTransaction? transaction}) async {
    final result = await showModalBottomSheet<FinanceTransaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionEditor(transaction: transaction),
    );
    if (result == null) return;
    setState(() {
      final index = _transactions.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _transactions.insert(0, result);
      } else {
        _transactions[index] = result;
      }
    });
    await _save();
  }

  Future<void> _delete(FinanceTransaction transaction) async {
    setState(() => _transactions.removeWhere((item) => item.id == transaction.id));
    await _save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa giao dịch')),
      );
    }
  }

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _green,
      brightness: _isDark ? Brightness.dark : Brightness.light,
      surface: _isDark ? const Color(0xFF18221F) : Colors.white,
    );
    return MaterialApp(
      title: 'MyFinance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _isDark ? const Color(0xFF101815) : _canvas,
        fontFamily: 'Roboto',
      ),
      home: !_loaded
          ? const _LoadingScreen()
          : FinanceHome(
              transactions: _transactions,
              onAdd: () => _openEditor(),
              onEdit: (item) => _openEditor(transaction: item),
              onDelete: _delete,
              isDark: _isDark,
              onToggleTheme: _toggleTheme,
            ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
}

class FinanceHome extends StatefulWidget {
  const FinanceHome({
    required this.transactions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
    required this.onToggleTheme,
    super.key,
  });

  final List<FinanceTransaction> transactions;
  final VoidCallback onAdd;
  final ValueChanged<FinanceTransaction> onEdit;
  final ValueChanged<FinanceTransaction> onDelete;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  int _tab = 0;
  String _filter = 'Tất cả';

  DateTime get _now => DateTime.now();

  List<FinanceTransaction> get _thisMonth => widget.transactions.where((item) {
        return item.date.year == _now.year && item.date.month == _now.month;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int get _income => _thisMonth
      .where((item) => item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  int get _expense => _thisMonth
      .where((item) => !item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  int get _balance => _income - _expense;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _transactionsPage(),
      _budgetPage(),
      _settingsPage(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      floatingActionButton: _tab == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.onAdd,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm giao dịch',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: _green.withValues(alpha: .12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Tổng quan'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Giao dịch'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Ngân sách'),
          NavigationDestination(
              icon: Icon(Icons.tune_rounded), label: 'Cài đặt'),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final recent = _thisMonth.take(4).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _topBar('Xin chào 👋', 'Cùng xem dòng tiền của bạn'),
              const SizedBox(height: 22),
              _balanceCard(),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Thu nhập',
                    amount: _income,
                    icon: Icons.south_west_rounded,
                    color: const Color(0xFF20A77A),
                    background: const Color(0xFFE8F7F0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'Chi tiêu',
                    amount: _expense,
                    icon: Icons.north_east_rounded,
                    color: const Color(0xFFE57962),
                    background: const Color(0xFFFFEEE9),
                  ),
                ),
              ]),
              const SizedBox(height: 26),
              _sectionHeader('Chi tiêu tháng này', action: 'Xem ngân sách',
                  onAction: () => setState(() => _tab = 2)),
              const SizedBox(height: 12),
              _spendingCard(),
              const SizedBox(height: 25),
              _sectionHeader('Giao dịch gần đây', action: 'Tất cả',
                  onAction: () => setState(() => _tab = 1)),
              const SizedBox(height: 6),
              if (recent.isEmpty)
                const _EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Chưa có giao dịch',
                    subtitle: 'Thêm giao dịch đầu tiên để theo dõi tài chính.'),
              ...recent.map((item) => _transactionTile(item)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _transactionsPage() {
    final filtered = _thisMonth.where((item) {
      if (_filter == 'Thu') return item.isIncome;
      if (_filter == 'Chi') return !item.isIncome;
      return true;
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      children: [
        _topBar('Giao dịch', 'Tháng ${_now.month}, ${_now.year}'),
        const SizedBox(height: 22),
        Row(children: ['Tất cả', 'Thu', 'Chi'].map((filter) {
          final active = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter == 'Thu' ? 'Thu nhập' : filter == 'Chi' ? 'Chi tiêu' : filter),
              selected: active,
              onSelected: (_) => setState(() => _filter = filter),
              selectedColor: _green.withValues(alpha: .14),
              side: BorderSide(color: active ? _green : Colors.transparent),
              labelStyle: TextStyle(
                color: active ? _green : _muted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        _miniTotals(),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          const _EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Chưa có giao dịch',
              subtitle: 'Các giao dịch trong tháng sẽ xuất hiện ở đây.'),
        ...filtered.map((item) => _transactionTile(item, editable: true)),
      ],
    );
  }

  Widget _budgetPage() {
    final spent = <String, int>{};
    for (final item in _thisMonth.where((item) => !item.isIncome)) {
      spent.update(item.category, (value) => value + item.amount,
          ifAbsent: () => item.amount);
    }
    final budgets = <String, int>{
      'Ăn uống': 4000000,
      'Đi lại': 1500000,
      'Hóa đơn': 2500000,
      'Mua sắm': 3000000,
      'Giải trí': 1200000,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      children: [
        _topBar('Ngân sách', 'Theo dõi giới hạn chi tiêu'),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tổng chi tiêu tháng này',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(_money(_expense),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28)),
            const SizedBox(height: 12),
            Text('${_thisMonth.where((e) => !e.isIncome).length} giao dịch chi tiêu',
                style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionHeader('Danh mục ngân sách'),
        const SizedBox(height: 10),
        ...budgets.entries.map((entry) {
          final value = spent[entry.key] ?? 0;
          final ratio = (value / entry.value).clamp(0.0, 1.0);
          final over = value > entry.value;
          final color = over ? const Color(0xFFE57962) : _green;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(context),
            child: Column(children: [
              Row(children: [
                _categoryIcon(entry.key),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${_money(value)} / ${_money(entry.value)}',
                        style: const TextStyle(color: _muted, fontSize: 12)),
                  ]),
                ),
                Text(over ? 'Vượt hạn mức' : '${(ratio * 100).round()}%',
                    style: TextStyle(
                        color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: color.withValues(alpha: .12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 6),
        Text('Hạn mức mẫu có thể chỉnh sửa trong phiên bản tiếp theo.',
            style: TextStyle(color: _muted.withValues(alpha: .9), fontSize: 12)),
      ],
    );
  }

  Widget _settingsPage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
        children: [
          _topBar('Cài đặt', 'Tùy chỉnh MyFinance'),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(context),
            child: Row(children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                    color: _green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: _green),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MyFinance',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  SizedBox(height: 4),
                  Text('Quản lý chi tiêu thông minh',
                      style: TextStyle(color: _muted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: _cardDecoration(context),
            child: SwitchListTile.adaptive(
              value: widget.isDark,
              onChanged: (_) => widget.onToggleTheme(),
              secondary: const Icon(Icons.dark_mode_outlined, color: _green),
              title: const Text('Giao diện tối',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Đổi giao diện sáng hoặc tối'),
              activeColor: _green,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: _cardDecoration(context),
            child: const Row(children: [
              Icon(Icons.lock_outline_rounded, color: _green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dữ liệu được lưu trên thiết bị của bạn. MyFinance chưa đồng bộ lên máy chủ.',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text('MyFinance • phiên bản 1.0.0',
                style: TextStyle(color: _muted.withValues(alpha: .8), fontSize: 12)),
          ),
        ],
      );

  Widget _topBar(String title, String subtitle) => Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.w800, fontSize: 24)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: _muted, fontSize: 13)),
            ]),
          ),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _ink),
          ),
        ],
      );

  Widget _balanceCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF147D64), Color(0xFF0E604F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: .20),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Số dư tháng này',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_monthName(_now.month),
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(_money(_balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                  letterSpacing: -.5)),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: .18)),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.trending_up_rounded, color: Colors.white70, size: 17),
            const SizedBox(width: 7),
            Text('${_thisMonth.length} giao dịch trong tháng',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white70, size: 18),
          ]),
        ]),
      );

  Widget _summaryCard({
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) => Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                  color: background, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 17, color: color),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          Text(_compactMoney(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          const Text('Trong tháng này',
              style: TextStyle(color: _muted, fontSize: 11)),
        ]),
      );

  Widget _spendingCard() {
    final categories = <String, int>{};
    for (final item in _thisMonth.where((item) => !item.isIncome)) {
      categories.update(item.category, (value) => value + item.amount,
          ifAbsent: () => item.amount);
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final colors = [
      _green,
      const Color(0xFF69BDA5),
      const Color(0xFFF2B36D),
    ];
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(context),
      child: Column(children: [
        Row(children: [
          SizedBox(
            height: 82,
            width: 82,
            child: _DonutChart(total: _expense, categories: top, colors: colors),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tổng chi tiêu',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 5),
              Text(_compactMoney(_expense),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: _ink, fontSize: 21)),
              const SizedBox(height: 4),
              Text('${sorted.length} danh mục',
                  style: const TextStyle(color: _muted, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: 17),
        if (top.isEmpty)
          const Text('Thêm khoản chi để xem thống kê theo danh mục.',
              style: TextStyle(color: _muted, fontSize: 12))
        else
          ...top.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final ratio = _expense == 0 ? 0.0 : row.value / _expense;
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Container(
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                      color: colors[i % colors.length], shape: BoxShape.circle),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(row.key,
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ),
                Text('${(ratio * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 12, color: _ink, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Text(_compactMoney(row.value),
                    style: const TextStyle(fontSize: 12, color: _ink)),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onAction}) =>
      Row(children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 5)),
            child: Text(action,
                style: const TextStyle(
                    color: _green, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
      ]);

  Widget _transactionTile(FinanceTransaction item, {bool editable = false}) {
    final tile = Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(context),
      child: Row(children: [
        _categoryIcon(item.category),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Text('${item.category} • ${_dateLabel(item.date)}',
                style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${item.isIncome ? '+' : '−'}${_compactMoney(item.amount)}',
            style: TextStyle(
                color: item.isIncome ? _green : const Color(0xFFE57962),
                fontWeight: FontWeight.w800,
                fontSize: 12)),
      ]),
    );
    if (!editable) return tile;
    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        margin: const EdgeInsets.only(top: 8),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
            color: _green, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(top: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: const Color(0xFFE57962),
            borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onEdit(item);
          return false;
        }
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xóa giao dịch?'),
                content: Text('Bạn muốn xóa “${item.title}”?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      child: const Text('Xóa')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => widget.onDelete(item),
      child: GestureDetector(
        onTap: () => widget.onEdit(item),
        child: tile,
      ),
    );
  }

  Widget _miniTotals() => Row(children: [
        Expanded(
          child: _miniTotal(
              'Thu nhập', _income, const Color(0xFF20A77A), Icons.south_west_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniTotal('Chi tiêu', _expense,
              const Color(0xFFE57962), Icons.north_east_rounded),
        ),
      ]);

  Widget _miniTotal(String label, int amount, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 3),
          Text(_compactMoney(amount),
              style: const TextStyle(
                  color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.total,
    required this.categories,
    required this.colors,
  });

  final int total;
  final List<MapEntry<String, int>> categories;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DonutPainter(total: total, values: categories, colors: colors),
        child: Center(
          child: Icon(Icons.pie_chart_rounded,
              color: _green.withValues(alpha: .8), size: 25),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.total, required this.values, required this.colors});

  final int total;
  final List<MapEntry<String, int>> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final base = Paint()
      ..color = const Color(0xFFE9EFEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.283, false, base);
    if (total == 0) return;
    var start = -1.5708;
    for (var i = 0; i < values.length; i++) {
      final sweep = 6.283 * values[i].value / total;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + .025;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.values != values;
}

class TransactionEditor extends StatefulWidget {
  const TransactionEditor({this.transaction, super.key});
  final FinanceTransaction? transaction;

  @override
  State<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends State<TransactionEditor> {
  static const _incomeCategories = ['Lương', 'Thu nhập khác', 'Đầu tư', 'Quà tặng'];
  static const _expenseCategories = [
    'Ăn uống',
    'Đi lại',
    'Hóa đơn',
    'Mua sắm',
    'Giải trí',
    'Sức khỏe',
    'Nhà cửa',
    'Khác',
  ];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late bool _isIncome;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _title = TextEditingController(text: transaction?.title ?? '');
    _amount = TextEditingController(
        text: transaction == null ? '' : transaction.amount.toString());
    _note = TextEditingController(text: transaction?.note ?? '');
    _isIncome = transaction?.isIncome ?? false;
    _category = transaction?.category ?? _expenseCategories.first;
    _date = transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    if (!categories.contains(_category)) _category = categories.first;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Text(widget.transaction == null ? 'Thêm giao dịch' : 'Sửa giao dịch',
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      label: Text('Chi tiêu'),
                      icon: Icon(Icons.north_east_rounded)),
                  ButtonSegment(
                      value: true,
                      label: Text('Thu nhập'),
                      icon: Icon(Icons.south_west_rounded)),
                ],
                selected: {_isIncome},
                onSelectionChanged: (value) =>
                    setState(() => _isIncome = value.first),
                style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? _green : _muted)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Số tiền (₫)', Icons.payments_outlined),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').replaceAll(',', '').trim());
                  if (amount == null || amount <= 0) return 'Nhập số tiền hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('Tên giao dịch', Icons.edit_note_rounded),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nhập tên giao dịch'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration('Danh mục', Icons.category_outlined),
                items: categories
                    .map((category) => DropdownMenuItem(
                        value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _inputDecoration('Ngày giao dịch', Icons.calendar_today_outlined),
                  child: Text(_dateLabel(_date),
                      style: const TextStyle(color: _ink, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('Ghi chú (không bắt buộc)', Icons.notes_rounded),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: Text(widget.transaction == null ? 'Lưu giao dịch' : 'Cập nhật',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _muted),
        filled: true,
        fillColor: _canvas.withValues(alpha: .65),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: _green)),
        child: child!,
      ),
    );
    if (date != null) setState(() => _date = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      FinanceTransaction(
        id: widget.transaction?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        category: _category,
        amount: int.parse(_amount.text.replaceAll(',', '').trim()),
        date: _date,
        isIncome: _isIncome,
        note: _note.text.trim(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(children: [
          Icon(icon, size: 34, color: _green.withValues(alpha: .65)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 5),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4)),
        ]),
      );
}

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(19),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );

Widget _categoryIcon(String category) {
  final (icon, background, foreground) = switch (category) {
    'Ăn uống' => (Icons.restaurant_rounded, const Color(0xFFFFF2E6), const Color(0xFFE69A55)),
    'Đi lại' => (Icons.directions_car_rounded, const Color(0xFFE9F2FF), const Color(0xFF5E91DB)),
    'Hóa đơn' => (Icons.receipt_rounded, const Color(0xFFFFEEEE), const Color(0xFFE57962)),
    'Lương' => (Icons.account_balance_wallet_rounded, const Color(0xFFE8F7F0), _green),
    'Mua sắm' => (Icons.shopping_bag_rounded, const Color(0xFFF5ECFF), const Color(0xFF9B71C9)),
    'Giải trí' => (Icons.movie_rounded, const Color(0xFFFFEDF5), const Color(0xFFD86D9A)),
    'Sức khỏe' => (Icons.favorite_rounded, const Color(0xFFFFEEEE), const Color(0xFFE57962)),
    _ => (Icons.category_rounded, const Color(0xFFEAF2EF), _green),
  };
  return Container(
    height: 42,
    width: 42,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
    child: Icon(icon, color: foreground, size: 19),
  );
}

String _money(int amount) => '${_digits(amount)} ₫';

String _compactMoney(int amount) {
  if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(1)} tỷ ₫';
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)} tr ₫';
  if (amount >= 1000) return '${(amount / 1000).round()}k ₫';
  return '$amount ₫';
}

String _digits(int value) {
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
    buffer.write(raw[i]);
  }
  return '${value < 0 ? '-' : ''}$buffer';
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Hôm nay';
  }
  if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
    return 'Hôm qua';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _monthName(int month) {
  const names = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
  ];
  return names[month - 1];
}
