import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/dates.dart';
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
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  late Future<_TransactionData> _future;
  TransactionType? _filter;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _future = _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void refresh() {
    if (mounted) setState(() => _future = _load());
  }

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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _error(snapshot.error!);

          final data = snapshot.data!;
          final query = _search.text.trim().toLowerCase();
          final rows = data.transactions.where((item) {
            final matchesType = _filter == null || item.type == _filter;
            final searchable = '${item.description} ${item.categoryName} ${item.walletName}'.toLowerCase();
            return matchesType && (query.isEmpty || searchable.contains(query));
          }).toList();

          final grouped = <String, List<FinanceTransaction>>{};
          for (final row in rows) {
            grouped.putIfAbsent(row.transactionDate, () => []).add(row);
          }
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giao dịch', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Thu nhập, chi tiêu và chuyển khoản', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _edit(data),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Thêm'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    hintText: 'Tìm giao dịch',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .4),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _filterChip('Tất cả', null),
                      _filterChip('Chi tiêu', TransactionType.expense),
                      _filterChip('Thu nhập', TransactionType.income),
                      _filterChip('Chuyển khoản', TransactionType.transfer),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: rows.isEmpty
                    ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'Không có giao dịch', message: 'Thay đổi bộ lọc hoặc thêm giao dịch mới.')
                    : RefreshIndicator(
                        onRefresh: () async {
                          final request = _load();
                          setState(() => _future = request);
                          await request;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                          itemCount: dates.length,
                          itemBuilder: (context, dateIndex) {
                            final date = dates[dateIndex];
                            final items = grouped[date]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                                  child: Text(
                                    formatDate(date).toUpperCase(),
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                        ),
                                  ),
                                ),
                                AppCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Column(
                                    children: [
                                      for (var i = 0; i < items.length; i++) ...[
                                        if (i > 0) const Divider(height: 1, indent: 64),
                                        Row(
                                          children: [
                                            Expanded(child: TransactionTile(transaction: items[i], onTap: () => _edit(data, items[i]))),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _edit(data, items[i]);
                                                } else {
                                                  _delete(items[i]);
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                                PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      );

  Widget _filterChip(String label, TransactionType? type) => ChoiceChip(
        label: Text(label),
        selected: _filter == type,
        onSelected: (_) => setState(() => _filter = type),
      );

  Widget _error(Object error) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Không thể tải giao dịch', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(error.toString(), textAlign: TextAlign.center), TextButton(onPressed: () => setState(() => _future = _load()), child: const Text('Thử lại'))])));
}

class _TransactionData {
  const _TransactionData(this.transactions, this.wallets, this.categories);
  final List<FinanceTransaction> transactions;
  final List<FinanceWallet> wallets;
  final List<FinanceCategory> categories;
}
