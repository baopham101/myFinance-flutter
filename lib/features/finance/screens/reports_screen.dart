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

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<FinanceTransaction>> _future;
  late DateTime _start;
  late DateTime _end;
  @override
  void initState() { super.initState(); final now = DateTime.now(); _start = DateTime(now.year, now.month, 1); _end = now; _future = widget.repository.transactions(widget.householdId); }
  String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  Future<void> _pick(bool start) async {
    final selected = await showDatePicker(context: context, initialDate: start ? _start : _end, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (selected != null) setState(() { if (start) { _start = selected; } else { _end = selected; } });
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
            GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.8, children: [
              _stat('Thu nhập', income, Theme.of(context).colorScheme.primary),
              _stat('Chi tiêu', expense, Theme.of(context).colorScheme.error),
              _stat('Chuyển khoản', transfer, Theme.of(context).colorScheme.tertiary),
              _stat('Chênh lệch', income - expense, Theme.of(context).colorScheme.onSurface),
            ]),
            const SizedBox(height: 14),
            const SectionTitle('Chi tiêu theo danh mục'),
            AppCard(child: categories.isEmpty ? const EmptyState(icon: Icons.bar_chart_rounded, title: 'Chưa có dữ liệu', message: 'Không có khoản chi trong khoảng thời gian này.') : Column(children: [
              ExpenseDonutChart(slices: categories.take(6).toList()),
              const SizedBox(height: 10),
              ...categories.map((item) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(radius: 6, backgroundColor: item.color), title: Text(item.label), trailing: Text(formatVnd(item.amount), style: const TextStyle(fontWeight: FontWeight.w700)))),
            ])),
            const SizedBox(height: 14),
            const SectionTitle('Giao dịch trong kỳ'),
            AppCard(child: rows.isEmpty ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Không có giao dịch', message: 'Thử chọn một khoảng thời gian khác.') : Column(children: [for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(height: 1), TransactionTile(transaction: rows[i])]])),
          ]);
        },
      );

  Widget _stat(String label, int amount, Color color) => AppCard(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 7), Text(formatVnd(amount), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800))]));
}

int _sum(List<FinanceTransaction> rows, TransactionType type) => rows.where((item) => item.type == type).fold<int>(0, (sum, item) => sum + item.amount);
Color _parseColor(String? value) { final hex = int.tryParse((value ?? '').replaceFirst('#', ''), radix: 16); return hex == null ? const Color(0xFF94A3B8) : Color(0xFF000000 | hex); }
