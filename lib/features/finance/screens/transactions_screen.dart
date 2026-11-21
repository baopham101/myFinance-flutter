import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';
import '../widgets/transaction_editor_sheet.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({required this.repository, required this.householdId, super.key});
  final FinanceRepository repository;
  final String? householdId;
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<_TransactionData> _future;
  TransactionType? _filter;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _future = _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<_TransactionData> _load() async {
    final results = await Future.wait([
      widget.repository.transactions(widget.householdId),
      widget.repository.wallets(widget.householdId),
      widget.repository.categories(widget.householdId),
    ]);
    return _TransactionData(results[0] as List<FinanceTransaction>, results[1] as List<FinanceWallet>, results[2] as List<FinanceCategory>);
  }

  Future<void> _edit(_TransactionData data, [FinanceTransaction? item]) async {
    if (data.wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy tạo một ví trước khi thêm giao dịch.')));
      return;
    }
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TransactionEditorSheet(repository: widget.repository, wallets: data.wallets, categories: data.categories, householdId: widget.householdId, transaction: item),
    );
    if (changed == true && mounted) setState(() => _future = _load());
  }

  Future<void> _delete(FinanceTransaction item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa giao dịch?'),
      content: const Text('Giao dịch sẽ được ẩn khỏi báo cáo và số dư.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))],
    ));
    if (confirmed != true) return;
    try {
      await widget.repository.deleteTransaction(item.id);
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_TransactionData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _error(snapshot.error!);
          final data = snapshot.data!;
          final query = _search.text.trim().toLowerCase();
          final rows = data.transactions.where((item) => (_filter == null || item.type == _filter) && (query.isEmpty || '${item.description} ${item.categoryName} ${item.walletName}'.toLowerCase().contains(query))).toList();
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 8), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Giao dịch', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), Text('Thu nhập, chi tiêu và chuyển khoản', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
              FilledButton.icon(onPressed: () => _edit(data), icon: const Icon(Icons.add_rounded), label: const Text('Thêm')),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Tìm giao dịch')),
            const SizedBox(height: 7),
            SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 18), children: [
              _filterChip('Tất cả', null),
              _filterChip('Chi tiêu', TransactionType.expense),
              _filterChip('Thu nhập', TransactionType.income),
              _filterChip('Chuyển khoản', TransactionType.transfer),
            ])),
            const SizedBox(height: 6),
            Expanded(child: rows.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Không có giao dịch', message: 'Thay đổi bộ lọc hoặc thêm giao dịch mới.')
                : RefreshIndicator(onRefresh: () async { final request = _load(); setState(() => _future = request); await request; }, child: ListView.separated(padding: const EdgeInsets.fromLTRB(14, 6, 14, 24), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 1), itemBuilder: (context, index) => AppCard(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: Row(children: [Expanded(child: TransactionTile(transaction: rows[index], onTap: () => _edit(data, rows[index]))), PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') _edit(data, rows[index]); else _delete(rows[index]); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Sửa')), PopupMenuItem(value: 'delete', child: Text('Xóa'))])])))),
          ]);
        },
      );

  Widget _filterChip(String label, TransactionType? type) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: _filter == type, onSelected: (_) => setState(() => _filter = type)));

  Widget _error(Object error) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Không thể tải giao dịch', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(error.toString(), textAlign: TextAlign.center), TextButton(onPressed: () => setState(() => _future = _load()), child: const Text('Thử lại'))])));
}

class _TransactionData {
  const _TransactionData(this.transactions, this.wallets, this.categories);
  final List<FinanceTransaction> transactions;
  final List<FinanceWallet> wallets;
  final List<FinanceCategory> categories;
}
