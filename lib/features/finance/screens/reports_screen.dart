import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/widgets/charts.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';
import '../widgets/transaction_tile.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.repository, required this.householdId, super.key});
  final FinanceRepository repository;
  final String? householdId;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late Future<List<FinanceTransaction>> _future;
  late DateTime _start;
  late DateTime _end;
  late final AnimationController _chartAnimController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = now;
    _future = widget.repository.transactions(widget.householdId);
    _chartAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final media = MediaQuery.of(context);
      if (!media.disableAnimations) {
        _chartAnimController.forward();
      } else {
        _chartAnimController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    super.dispose();
  }

  String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final selected = await showDatePicker(context: context, initialDate: start ? _start : _end, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (selected != null) setState(() { if (start) { _start = selected; } else { _end = selected; } _chartAnimController.forward(from: 0); });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FinanceTransaction>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Không thể tải báo cáo: ${snapshot.error}'));
          final start = _date(_start), end = _date(_end);
          final rows = (snapshot.data ?? []).where((item) => item.transactionDate.compareTo(start) >= 0 && item.transactionDate.compareTo(end) <= 0).toList();
          final income = _sum(rows, TransactionType.income), expense = _sum(rows, TransactionType.expense), transfer = _sum(rows, TransactionType.transfer);
          final net = income - expense;

          // Build monthly trend data for selected range
          final trendPoints = _buildTrendPoints(rows, start, end);
          final totals = <String, ExpenseSlice>{};
          for (final item in rows.where((item) => item.type == TransactionType.expense)) {
            final label = item.categoryName ?? 'Không danh mục';
            final old = totals[label];
            totals[label] = ExpenseSlice(label: label, amount: (old?.amount ?? 0) + item.amount, color: _parseColor(item.categoryColor));
          }
          final categories = totals.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));

          return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
            Text('Báo cáo', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text('Phân tích thu chi theo khoảng thời gian', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.calendar_today_outlined, size: 18), label: Text(_date(_start)))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.event_outlined, size: 18), label: Text(_date(_end))))]),
            if (_date(_end).compareTo(_date(_start)) < 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ngày kết thúc phải sau ngày bắt đầu.', style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 14),

            // Summary cards with better visual hierarchy
            _buildSummaryCards(income, expense, transfer, net),

            const SizedBox(height: 14),

            // Monthly trend chart
            if (trendPoints.isNotEmpty) ...[
              SectionTitle('Xu hướng thu chi'),
              AppCard(
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Wrap(spacing: 14, children: [
                      _LegendDot(color: Color(0xFF16845B), label: 'Thu nhập'),
                      _LegendDot(color: Color(0xFFDB5B62), label: 'Chi tiêu'),
                    ]),
                    const SizedBox(height: 14),
                    CashFlowChart(points: trendPoints),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Category breakdown
            const SectionTitle('Chi tiêu theo danh mục'),
            AppCard(
              child: categories.isEmpty
                  ? const EmptyState(icon: Icons.bar_chart_rounded, title: 'Chưa có dữ liệu', message: 'Không có khoản chi trong khoảng thời gian này.')
                  : Column(children: [
                      ExpenseDonutChart(slices: categories.take(6).toList()),
                      const SizedBox(height: 10),
                      ...categories.map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(radius: 6, backgroundColor: item.color),
                            title: Text(item.label),
                            trailing: Text(formatVnd(item.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                          )),
                    ]),
            ),
            const SizedBox(height: 14),

            // Transaction list
            const SectionTitle('Giao dịch trong kỳ'),
            AppCard(
              child: rows.isEmpty
                  ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Không có giao dịch', message: 'Thử chọn một khoảng thời gian khác.')
                  : Column(
                      children: [for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(height: 1), TransactionTile(transaction: rows[i])]],
                    ),
            ),
          ]);
        },
      );

  Widget _buildSummaryCards(int income, int expense, int transfer, int net) {
    final isPositive = net >= 0;
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: [
        _StatCard(
          label: 'Thu nhập',
          amount: formatVnd(income),
          icon: Icons.south_west_rounded,
          color: Theme.of(context).colorScheme.primary,
          background: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
        ),
        _StatCard(
          label: 'Chi tiêu',
          amount: formatVnd(expense),
          icon: Icons.north_east_rounded,
          color: Theme.of(context).colorScheme.error,
          background: Theme.of(context).colorScheme.error.withValues(alpha: .1),
        ),
        _StatCard(
          label: 'Chuyển khoản',
          amount: formatVnd(transfer),
          icon: Icons.swap_horiz_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          background: Theme.of(context).colorScheme.tertiary.withValues(alpha: .1),
        ),
        _StatCard(
          label: 'Chênh lệch',
          amount: formatVnd(net),
          icon: isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: isPositive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
          background: (isPositive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error).withValues(alpha: .1),
        ),
      ],
    );
  }

  List<CashFlowPoint> _buildTrendPoints(List<FinanceTransaction> rows, String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    final points = <CashFlowPoint>[];

    // Build all months in the range first (so zero-data months appear)
    var current = DateTime(startDate.year, startDate.month, 1);
    final lastMonth = DateTime(endDate.year, endDate.month, 1);
    final monthKeys = <String>[];
    while (!current.isAfter(lastMonth)) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}';
      monthKeys.add(key);
      points.add(CashFlowPoint(month: '${current.month}月', income: 0, expense: 0));
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Now aggregate actual data by month key
    final monthly = <String, CashFlowPoint>{};
    for (final row in rows) {
      final date = DateTime.parse(row.transactionDate);
      if (date.isBefore(startDate) || date.isAfter(endDate)) continue;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final existing = monthly[key] ?? CashFlowPoint(month: '${date.month}月', income: 0, expense: 0);
      if (row.type == TransactionType.income) {
        monthly[key] = CashFlowPoint(month: existing.month, income: existing.income + row.amount, expense: existing.expense);
      } else if (row.type == TransactionType.expense) {
        monthly[key] = CashFlowPoint(month: existing.month, income: existing.income, expense: existing.expense + row.amount);
      }
    }

    // Merge data into points
    for (var i = 0; i < monthKeys.length; i++) {
      final key = monthKeys[i];
      if (monthly.containsKey(key)) {
        points[i] = monthly[key]!;
      }
    }
    return points;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.amount, required this.icon, required this.color, required this.background});
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(13),
        color: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 7),
            Text(amount, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall)]);
}

int _sum(List<FinanceTransaction> rows, TransactionType type) => rows.where((item) => item.type == type).fold<int>(0, (sum, item) => sum + item.amount);
Color _parseColor(String? value) { final hex = int.tryParse((value ?? '').replaceFirst('#', ''), radix: 16); return hex == null ? const Color(0xFF94A3B8) : Color(0xFF000000 | hex); }
