import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_card.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({required this.repository, required this.householdId, this.onDataChanged, super.key});
  final FinanceRepository repository;
  final String? householdId;
  final VoidCallback? onDataChanged;
  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  late Future<List<FinanceWallet>> _future;
  @override
  void initState() { super.initState(); _future = widget.repository.wallets(widget.householdId); }

  Future<void> _edit([FinanceWallet? wallet]) async {
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _WalletEditor(repository: widget.repository, householdId: widget.householdId, wallet: wallet));
    if (saved == true && mounted) {
      setState(() { _future = widget.repository.wallets(widget.householdId); });
      widget.onDataChanged?.call();
    }
  }

  Future<void> _delete(FinanceWallet wallet) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Xóa ví?'), content: Text('Xóa ví “${wallet.name}”? Ví có giao dịch không thể xóa.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))]));
    if (confirmed != true) return;
    try { await widget.repository.deleteWallet(wallet.id); if (mounted) { setState(() { _future = widget.repository.wallets(widget.householdId); }); widget.onDataChanged?.call(); } }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FinanceWallet>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _screenError(context, snapshot.error!, () => setState(() => _future = widget.repository.wallets(widget.householdId)));
          final wallets = snapshot.data ?? [];
          return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ví của tôi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Tài khoản tiền mặt, ngân hàng và ví điện tử', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
              ])),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm ví'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            if (wallets.isEmpty) const AppCard(elevation: 0, child: EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'Chưa có ví', message: 'Tạo ví đầu tiên để ghi nhận số dư và giao dịch.')),
            ...wallets.map((wallet) => Padding(padding: const EdgeInsets.only(bottom: 12), child: AppCard(
              elevation: 0,
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_walletIcon(wallet.type), color: Theme.of(context).colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(_walletTypeLabel(wallet.type), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                const SizedBox(width: 8),
                // Wrap the balance + menu row in Flexible so it gets bounded constraints
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          formatVnd(wallet.balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Hành động',
                        onSelected: (value) => value == 'edit' ? _edit(wallet) : _delete(wallet),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Sửa ví')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa ví')),
                        ],
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ]),
            ))),
          ]);
        },
      );
}

class _WalletEditor extends StatefulWidget {
  const _WalletEditor({required this.repository, required this.householdId, this.wallet});
  final FinanceRepository repository;
  final String? householdId;
  final FinanceWallet? wallet;
  @override
  State<_WalletEditor> createState() => _WalletEditorState();
}

class _WalletEditorState extends State<_WalletEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late WalletType _type;
  bool _saving = false;
  String? _error;
  late bool _isEditing;
  @override
  void initState() { super.initState(); _name = TextEditingController(text: widget.wallet?.name ?? ''); _opening = TextEditingController(text: widget.wallet?.openingBalance.toString() ?? '0'); _type = widget.wallet?.type ?? WalletType.cash; _isEditing = widget.wallet != null; }
  @override
  void dispose() { _name.dispose(); _opening.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.wallet == null ? 'Tạo ví' : 'Sửa ví', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(controller: _name, autofocus: true, maxLength: 80, decoration: const InputDecoration(labelText: 'Tên ví', prefixIcon: Icon(Icons.account_balance_wallet_outlined)), validator: (value) => value == null || value.trim().isEmpty ? 'Nhập tên ví.' : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<WalletType>(initialValue: _type, decoration: const InputDecoration(labelText: 'Loại ví'), items: WalletType.values.map((item) => DropdownMenuItem(value: item, child: Text(_walletTypeLabel(item)))).toList(), onChanged: (value) => setState(() => _type = value!)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _opening,
                  enabled: !_isEditing,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số dư ban đầu (VND)',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    helperText: _isEditing ? 'Số dư ban đầu không thể thay đổi. Dùng giao dịch để điều chỉnh.' : null,
                    helperMaxLines: 2,
                  ),
                  validator: (value) { try { parseVnd(value ?? '', allowZero: true); return null; } on FormatException catch (error) { return error.message; } },
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 20),
                FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const CircularProgressIndicator() : const Text('Lưu ví')),
              ],
            ),
          ),
        ),
      );

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      if (widget.wallet != null) {
        // Editing existing wallet - don't pass openingBalance
        await widget.repository.saveWallet(id: widget.wallet?.id, name: _name.text.trim(), type: _type, householdId: widget.householdId);
      } else {
        // Creating new wallet - pass openingBalance
        await widget.repository.saveWallet(name: _name.text.trim(), type: _type, openingBalance: parseVnd(_opening.text, allowZero: true), householdId: widget.householdId);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) { if (mounted) setState(() { _saving = false; _error = error.toString().replaceFirst('Exception: ', ''); }); }
  }
}

String _walletTypeLabel(WalletType type) => switch (type) { WalletType.cash => 'Tiền mặt', WalletType.bank => 'Tài khoản ngân hàng', WalletType.card => 'Thẻ', WalletType.eWallet => 'Ví điện tử', WalletType.savings => 'Tiết kiệm' };
IconData _walletIcon(WalletType type) => switch (type) { WalletType.cash => Icons.payments_outlined, WalletType.bank => Icons.account_balance_outlined, WalletType.card => Icons.credit_card_rounded, WalletType.eWallet => Icons.phone_android_rounded, WalletType.savings => Icons.savings_outlined };

Widget _screenError(BuildContext context, Object error, VoidCallback retry) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Không thể tải dữ liệu', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(error.toString(), textAlign: TextAlign.center), TextButton(onPressed: retry, child: const Text('Thử lại'))])));
