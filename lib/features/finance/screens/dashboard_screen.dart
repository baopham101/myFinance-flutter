import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/widgets/charts.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.repository, required this.householdId, required this.onNavigate, required this.onAddTransaction, super.key});
  final FinanceRepository repository;
  final String? householdId;
  final ValueChanged<String> onNavigate;
  final VoidCallback onAddTransaction;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late Future<_DashboardData> _future;
  bool _showBalance = true;
  late final AnimationController _balanceController;
  late final AnimationController _summaryController;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _balanceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _summaryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Animate summary tiles on initial load
    final media = MediaQuery.of(context);
    if (!media.disableAnimations) {
      _summaryController.forward();
    } else {
      _summaryController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _toggleBalance() => setState(() {
        _showBalance = !_showBalance;
        _showBalance ? _balanceController.forward() : _balanceController.reverse();
      });

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the data source changed (different key), re-animate summary tiles
    if (widget.key != oldWidget.key) {
      _summaryController.forward(from: 0);
    }
  }

  Future<_DashboardData> _load() async {
    final values = await Future.wait([
      widget.repository.wallets(widget.householdId),
      widget.repository.transactions(widget.householdId),
    ]);
    final wallets = values[0] as List<FinanceWallet>;
    final transactions = values[1] as List<FinanceTransaction>;
    final now = DateTime.now();
    final currentMonth = transactions.where((item) => item.transactionDate.startsWith('${now.year}-${now.month.toString().padLeft(2, '0')}')).toList();
    final income = currentMonth.where((item) => item.type == TransactionType.income).fold<int>(0, (sum, item) => sum + item.amount);
    final expense = currentMonth.where((item) => item.type == TransactionType.expense).fold<int>(0, (sum, item) => sum + item.amount);
    final flow = <CashFlowPoint>[];
    for (var back = 5; back >= 0; back--) {
      final date = DateTime(now.year, now.month - back, 1);
      final prefix = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final rows = transactions.where((item) => item.transactionDate.startsWith(prefix));
      flow.add(CashFlowPoint(
        month: '${date.month}月',
        income: rows.where((item) => item.type == TransactionType.income).fold<int>(0, (sum, item) => sum + item.amount),
        expense: rows.where((item) => item.type == TransactionType.expense).fold<int>(0, (sum, item) => sum + item.amount),
      ));
    }
    final categoryTotals = <String, ExpenseSlice>{};
    for (final item in currentMonth.where((item) => item.type == TransactionType.expense)) {
      final key = item.categoryName ?? 'Khác';
      final previous = categoryTotals[key];
      categoryTotals[key] = ExpenseSlice(label: key, amount: (previous?.amount ?? 0) + item.amount, color: _colorFromHex(item.categoryColor));
    }
    final categories = categoryTotals.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return _DashboardData(
      balance: wallets.fold<int>(0, (sum, wallet) => sum + wallet.balance),
      income: income,
      expense: expense,
      transactions: transactions.take(5).toList(),
      flow: flow,
      categories: categories.take(5).toList(),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _error(snapshot.error!);
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              final request = _load();
              setState(() => _future = request);
              await request;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Tổng quan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Dòng tiền của bạn trong tháng này', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                      ]),
                      FilledButton.icon(
                        onPressed: widget.onAddTransaction,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Thêm giao dịch'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _balanceController,
                  builder: (context, _) => AppCard(
                    padding: const EdgeInsets.all(20),
                    elevation: 0,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                        Theme.of(context).colorScheme.primary.withValues(alpha: .04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng số dư', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                          IconButton(
                            tooltip: _showBalance ? 'Ẩn số dư' : 'Hiện số dư',
                            onPressed: _toggleBalance,
                            icon: Icon(_showBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim), child: child)),
                        child: _showBalance
                            ? Text(
                                formatVnd(data.balance),
                                key: const ValueKey('shown'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
                              )
                            : Text(
                                '••••••••',
                                key: const ValueKey('hidden'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
                              ),
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: _summary(context, 'Thu nhập tháng này', data.income, Icons.south_west_rounded, Theme.of(context).colorScheme.primary, _summaryController)),
                        const SizedBox(width: 12),
                        Expanded(child: _summary(context, 'Chi tiêu tháng này', data.expense, Icons.north_east_rounded, Theme.of(context).colorScheme.error, _summaryController)),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
                const SizedBox(height: 20),
                SectionTitle('Dòng tiền', action: 'Báo cáo', onAction: () => widget.onNavigate('reports')),
                AppCard(elevation: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Thu nhập và chi tiêu · 6 tháng', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  const Wrap(spacing: 14, children: [
                    _LegendDot(color: Color(0xFF16845B), label: 'Thu nhập'),
                    _LegendDot(color: Color(0xFFDB5B62), label: 'Chi tiêu'),
                  ]),
                  const SizedBox(height: 14),
                  CashFlowChart(points: data.flow),
                ])),
                const SizedBox(height: 20),
                SectionTitle('Chi tiêu theo danh mục', action: 'Xem báo cáo', onAction: () => widget.onNavigate('reports')),
                AppCard(
                  elevation: 0,
                  child: data.categories.isEmpty
                      ? const EmptyState(icon: Icons.pie_chart_outline_rounded, title: 'Chưa có khoản chi', message: 'Giao dịch chi tiêu sẽ được phân tích tại đây.')
                      : ExpenseDonutChart(slices: data.categories),
                ),
                const SizedBox(height: 20),
                SectionTitle('Giao dịch gần đây', action: 'Tất cả', onAction: () => widget.onNavigate('transactions')),
                AppCard(
                  elevation: 0,
                  child: data.transactions.isEmpty
                      ? const EmptyState(icon: Icons.receipt_long_rounded, title: 'Chưa có giao dịch', message: 'Thêm khoản thu hoặc chi đầu tiên của bạn.')
                      : Column(children: [
                          for (var i = 0; i < data.transactions.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            TransactionTile(transaction: data.transactions[i]),
                          ],
                        ]),
                ),
              ],
            ),
          );
        },
      );

  Widget _summary(BuildContext context, String title, int amount, IconData icon, Color color, Animation<double> animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(15)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 9),
                Text(title, maxLines: 2, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 5),
                Text(formatVnd(amount), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      );

  Widget _error(Object error) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_rounded, size: 38),
    const SizedBox(height: 12),
    const Text('Không thể tải tổng quan', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    Text(error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    const SizedBox(height: 12),
    OutlinedButton.icon(onPressed: () => setState(() => _future = _load()), icon: const Icon(Icons.refresh_rounded), label: const Text('Thử lại')),
  ])));
}

class _DashboardData {
  const _DashboardData({required this.balance, required this.income, required this.expense, required this.transactions, required this.flow, required this.categories});
  final int balance, income, expense;
  final List<FinanceTransaction> transactions;
  final List<CashFlowPoint> flow;
  final List<ExpenseSlice> categories;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall)]);
}

Color _colorFromHex(String? value) {
  if (value == null) return const Color(0xFF94A3B8);
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? const Color(0xFF94A3B8) : Color(0xFF000000 | parsed);
}
