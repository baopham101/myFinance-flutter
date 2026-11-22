import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/dates.dart';
import '../../../core/formatters/money.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';

class TransactionEditorSheet extends StatefulWidget {
  const TransactionEditorSheet({required this.repository, required this.wallets, required this.categories, required this.householdId, this.transaction, super.key});
  final FinanceRepository repository;
  final List<FinanceWallet> wallets;
  final List<FinanceCategory> categories;
  final String? householdId;
  final FinanceTransaction? transaction;

  @override
  State<TransactionEditorSheet> createState() => _TransactionEditorSheetState();
}

class _TransactionEditorSheetState extends State<TransactionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late TransactionType _type;
  late String? _walletId;
  late String? _destinationId;
  late String? _categoryId;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  List<FinanceCategory> get _categories => widget.categories.where((item) => item.type == _type.name).toList();

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _amount = TextEditingController(text: transaction == null ? '' : transaction.amount.toString());
    _description = TextEditingController(text: transaction?.description ?? '');
    _type = transaction?.type ?? TransactionType.expense;
    _walletId = transaction?.walletId ?? (widget.wallets.isEmpty ? null : widget.wallets.first.id);
    _destinationId = transaction?.toWalletId ?? widget.wallets.where((wallet) => wallet.id != _walletId).firstOrNull?.id;
    final filtered = widget.categories.where((item) => item.type == _type.name);
    _categoryId = transaction?.categoryId ?? filtered.firstOrNull?.id;
    _date = transaction == null ? DateTime.now() : DateTime.tryParse(transaction.transactionDate) ?? DateTime.now();
  }

  @override
  void dispose() { _amount.dispose(); _description.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(5)))),
                const SizedBox(height: 18),
                Text(widget.transaction == null ? 'Thêm giao dịch' : 'Sửa giao dịch', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.expense, label: Text('Chi'), icon: Icon(Icons.north_east_rounded)),
                    ButtonSegment(value: TransactionType.income, label: Text('Thu'), icon: Icon(Icons.south_west_rounded)),
                    ButtonSegment(value: TransactionType.transfer, label: Text('Chuyển'), icon: Icon(Icons.swap_horiz_rounded)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => setState(() {
                    _type = selection.first;
                    _categoryId = _categories.firstOrNull?.id;
                  }),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amount,
                  autofocus: widget.transaction == null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền (VND)', prefixIcon: Icon(Icons.payments_outlined)),
                  validator: (value) { try { parseVnd(value ?? ''); return null; } on FormatException catch (error) { return error.message; } },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _walletId,
                  decoration: const InputDecoration(labelText: 'Ví nguồn', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                  items: widget.wallets.map((wallet) => DropdownMenuItem(value: wallet.id, child: Text('${wallet.name} · ${formatVnd(wallet.balance)}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) => setState(() { _walletId = value; if (_destinationId == value) _destinationId = widget.wallets.where((item) => item.id != value).firstOrNull?.id; }),
                  validator: (value) => value == null ? 'Tạo ví trước khi thêm giao dịch.' : null,
                ),
                if (_type == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _destinationId,
                    decoration: const InputDecoration(labelText: 'Ví nhận', prefixIcon: Icon(Icons.call_received_rounded)),
                    items: widget.wallets.where((wallet) => wallet.id != _walletId).map((wallet) => DropdownMenuItem(value: wallet.id, child: Text(wallet.name))).toList(),
                    onChanged: (value) => setState(() => _destinationId = value),
                    validator: (value) => value == null ? 'Chọn ví nhận khác ví nguồn.' : null,
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Danh mục', prefixIcon: Icon(Icons.category_outlined)),
                    items: _categories.map((category) => DropdownMenuItem(value: category.id, child: Text(category.name))).toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) => value == null ? 'Tạo danh mục ${_type == TransactionType.expense ? 'chi tiêu' : 'thu nhập'} trước.' : null,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today_outlined), label: Text('Ngày: ${formatDate(_date.toIso8601String())}')),
                const SizedBox(height: 12),
                TextFormField(controller: _description, textCapitalization: TextCapitalization.sentences, maxLength: 300, decoration: const InputDecoration(labelText: 'Mô tả (không bắt buộc)', prefixIcon: Icon(Icons.notes_rounded)),),
                if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
                const SizedBox(height: 12),
                FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.transaction == null ? 'Lưu giao dịch' : 'Cập nhật giao dịch')),
              ]),
            ),
          ),
        ),
      );

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (chosen != null) setState(() => _date = chosen);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await widget.repository.saveTransaction(
        id: widget.transaction?.id,
        type: _type,
        amount: parseVnd(_amount.text),
        walletId: _walletId!,
        toWalletId: _type == TransactionType.transfer ? _destinationId : null,
        categoryId: _type == TransactionType.transfer ? null : _categoryId,
        description: _description.text.trim(),
        transactionDate: '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        householdId: widget.householdId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() { _saving = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }
}
