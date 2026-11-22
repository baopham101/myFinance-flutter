import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_card.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({required this.repository, required this.householdId, super.key});
  final FinanceRepository repository;
  final String? householdId;
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late Future<_BudgetData> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<_BudgetData> _load() async {
    final values = await Future.wait([widget.repository.budgets(widget.householdId), widget.repository.categories(widget.householdId)]);
    return _BudgetData(values[0] as List<FinanceBudget>, values[1] as List<FinanceCategory>);
  }

  Future<void> _edit(_BudgetData data, [FinanceBudget? budget]) async {
    final categories = data.categories.where((item) => item.type == 'expense').toList();
    if (categories.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy tạo danh mục chi tiêu trước.'))); return; }
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _BudgetEditor(repository: widget.repository, householdId: widget.householdId, categories: categories, budget: budget));
    if (saved == true && mounted) setState(() => _future = _load());
  }

  Future<void> _delete(FinanceBudget budget) async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Xóa ngân sách?'), content: Text('Ẩn ngân sách ${budget.categoryName}?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))]));
    if (yes != true) return;
    try { await widget.repository.deleteBudget(budget.id); if (mounted) setState(() => _future = _load()); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_BudgetData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Không thể tải ngân sách: ${snapshot.error}'));
          final data = snapshot.data!;
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final active = data.budgets.where((item) => item.periodStart.compareTo(today) <= 0 && item.periodEnd.compareTo(today) >= 0).toList();
          final totalLimit = active.fold<int>(0, (sum, item) => sum + item.limitAmount);
          final totalSpent = active.fold<int>(0, (sum, item) => sum + item.spent);
          return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ngân sách', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Giới hạn chi tiêu theo danh mục', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
              ])),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _edit(data),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tạo ngân sách'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            AppCard(
              elevation: 0,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Đang dùng trong kỳ này', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 8),
                Text(formatVnd(totalSpent), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('trên tổng hạn mức ${formatVnd(totalLimit)}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: totalLimit == 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            if (data.budgets.isEmpty) const AppCard(elevation: 0, child: EmptyState(icon: Icons.pie_chart_outline_rounded, title: 'Chưa có ngân sách', message: 'Tạo giới hạn chi tiêu cho một danh mục.')),
            ...data.budgets.map((budget) {
              final percent = budget.limitAmount == 0 ? 0 : (budget.spent * 100 / budget.limitAmount).round();
              final ratio = (budget.spent / budget.limitAmount).clamp(0.0, 1.0).toDouble();
              final color = percent >= 100 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: AppCard(
                elevation: 0,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(budget.categoryName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${budget.periodStart} — ${budget.periodEnd}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ])),
                    Text('$percent%', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
                    PopupMenuButton<String>(
                      onSelected: (value) => value == 'edit' ? _edit(data, budget) : _delete(budget),
                      itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Sửa')), PopupMenuItem(value: 'delete', child: Text('Xóa'))],
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: color,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatVnd(budget.spent)} / ${formatVnd(budget.limitAmount)} · ${budget.spent > budget.limitAmount ? 'Vượt hạn mức' : 'Còn ${formatVnd(budget.limitAmount - budget.spent)}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ]),
              ));
            }),
          ]);
        },
      );
}

class _BudgetData { const _BudgetData(this.budgets, this.categories); final List<FinanceBudget> budgets; final List<FinanceCategory> categories; }

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({required this.repository, required this.householdId, required this.categories, this.budget});
  final FinanceRepository repository;
  final String? householdId;
  final List<FinanceCategory> categories;
  final FinanceBudget? budget;
  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _limit;
  late String _categoryId;
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _limit = TextEditingController(text: widget.budget?.limitAmount.toString() ?? '');
    _categoryId = widget.budget?.categoryId ?? widget.categories.first.id;
    _start = DateTime.tryParse(widget.budget?.periodStart ?? '') ?? DateTime(now.year, now.month, 1);
    _end = DateTime.tryParse(widget.budget?.periodEnd ?? '') ?? DateTime(now.year, now.month + 1, 0);
  }
  @override
  void dispose() { _limit.dispose(); super.dispose(); }
  String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(widget.budget == null ? 'Tạo ngân sách' : 'Sửa ngân sách', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 14),
    DropdownButtonFormField<String>(initialValue: _categoryId, decoration: const InputDecoration(labelText: 'Danh mục chi tiêu'), items: widget.categories.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(), onChanged: (value) => setState(() => _categoryId = value!)),
    const SizedBox(height: 12),
    TextFormField(controller: _limit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hạn mức (VND)'), validator: (value) { try { parseVnd(value ?? ''); return null; } on FormatException catch (error) { return error.message; } }),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.calendar_today_outlined), label: Text('Bắt đầu: ${_date(_start)}')),
    OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.event_outlined), label: Text('Kết thúc: ${_date(_end)}')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    const SizedBox(height: 12),
    FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const CircularProgressIndicator() : const Text('Lưu ngân sách')),
  ]))));

  Future<void> _pick(bool start) async {
    final selected = await showDatePicker(context: context, initialDate: start ? _start : _end, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (selected != null) setState(() { if (start) { _start = selected; } else { _end = selected; } });
  }
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_date(_end).compareTo(_date(_start)) < 0) { setState(() => _error = 'Ngày kết thúc phải bằng hoặc sau ngày bắt đầu.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repository.saveBudget(id: widget.budget?.id, categoryId: _categoryId, limitAmount: parseVnd(_limit.text), start: _date(_start), end: _date(_end), householdId: widget.householdId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) { if (mounted) setState(() { _saving = false; _error = error.toString().replaceFirst('Exception: ', ''); }); }
  }
}
