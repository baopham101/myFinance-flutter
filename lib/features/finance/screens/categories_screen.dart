import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_card.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({required this.repository, required this.householdId, super.key});
  final FinanceRepository repository;
  final String? householdId;
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<FinanceCategory>> _future;
  @override
  void initState() { super.initState(); _future = widget.repository.categories(widget.householdId); }

  Future<void> _edit([FinanceCategory? category]) async {
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _CategoryEditor(repository: widget.repository, householdId: widget.householdId, category: category));
    if (saved == true && mounted) setState(() => _future = widget.repository.categories(widget.householdId));
  }

  Future<void> _delete(FinanceCategory category) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Ẩn danh mục?'), content: Text('Danh mục “${category.name}” sẽ được ẩn. Giao dịch cũ vẫn giữ nguyên.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ẩn'))]));
    if (confirmed != true) return;
    try { await widget.repository.deleteCategory(category.id); if (mounted) setState(() => _future = widget.repository.categories(widget.householdId)); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FinanceCategory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Không thể tải danh mục: ${snapshot.error}'));
          final categories = snapshot.data ?? [];
          return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
            Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Danh mục', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), Text('Tổ chức các khoản thu và chi', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])), FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add_rounded), label: const Text('Thêm'))]),
            const SizedBox(height: 18),
            for (final type in ['expense', 'income']) ...[
              Text(type == 'expense' ? 'CHI TIÊU' : 'THU NHẬP', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              AppCard(child: Column(children: [
                ...categories.where((item) => item.type == type).map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: _hexColor(item.color).withValues(alpha: .13), child: Icon(Icons.sell_outlined, color: _hexColor(item.color), size: 20)),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Wrap(children: [IconButton(tooltip: 'Sửa', onPressed: () => _edit(item), icon: const Icon(Icons.edit_outlined, size: 19)), IconButton(tooltip: 'Ẩn', onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline_rounded, size: 19))]),
                )),
                if (!categories.any((item) => item.type == type)) const Padding(padding: EdgeInsets.all(12), child: Text('Chưa có danh mục.')),
              ])),
              const SizedBox(height: 16),
            ],
          ]);
        },
      );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.repository, required this.householdId, this.category});
  final FinanceRepository repository;
  final String? householdId;
  final FinanceCategory? category;
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  static const _palette = [Color(0xFFE46B50), Color(0xFFF2A65A), Color(0xFF4E78A3), Color(0xFF7D8EA3), Color(0xFF9B7AC7), Color(0xFFD278A3), Color(0xFF16845B), Color(0xFF3B9D7A)];
  late final TextEditingController _name;
  late String _type;
  late Color _color;
  bool _saving = false;
  String? _error;
  @override
  void initState() { super.initState(); _name = TextEditingController(text: widget.category?.name ?? ''); _type = widget.category?.type ?? 'expense'; _color = _hexColor(widget.category?.color ?? '#16845b'); }
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(widget.category == null ? 'Thêm danh mục' : 'Sửa danh mục', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 14),
    TextField(controller: _name, autofocus: true, maxLength: 80, decoration: const InputDecoration(labelText: 'Tên danh mục')),
    const SizedBox(height: 8),
    SegmentedButton<String>(segments: const [ButtonSegment(value: 'expense', label: Text('Chi tiêu')), ButtonSegment(value: 'income', label: Text('Thu nhập'))], selected: {_type}, onSelectionChanged: (selection) => setState(() => _type = selection.first)),
    const SizedBox(height: 14),
    Text('Màu danh mục', style: Theme.of(context).textTheme.labelLarge),
    const SizedBox(height: 8),
    Wrap(spacing: 10, children: _palette.map((color) => InkWell(onTap: () => setState(() => _color = color), borderRadius: BorderRadius.circular(20), child: CircleAvatar(radius: 17, backgroundColor: color, child: _color.toARGB32() == color.toARGB32() ? const Icon(Icons.check, size: 17, color: Colors.white) : null))).toList()),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    const SizedBox(height: 16),
    FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const CircularProgressIndicator() : const Text('Lưu danh mục')),
  ])));

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) { setState(() => _error = 'Nhập tên danh mục.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repository.saveCategory(id: widget.category?.id, name: _name.text.trim(), type: _type, color: '#${_color.toARGB32().toRadixString(16).substring(2)}', householdId: widget.householdId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) { if (mounted) setState(() { _saving = false; _error = error.toString().replaceFirst('Exception: ', ''); }); }
  }
}

Color _hexColor(String value) { final parsed = int.tryParse(value.replaceFirst('#', ''), radix: 16); return parsed == null ? const Color(0xFF16845B) : Color(0xFF000000 | parsed); }
