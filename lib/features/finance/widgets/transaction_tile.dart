import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/money.dart';
import '../data/models.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, super.key});
  final FinanceTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final color = isIncome ? scheme.primary : isTransfer ? scheme.tertiary : scheme.error;
    final icon = isIncome ? Icons.south_west_rounded : isTransfer ? Icons.swap_horiz_rounded : Icons.north_east_rounded;
    final title = transaction.description.trim().isNotEmpty
        ? transaction.description
        : isTransfer
            ? 'Chuyển tiền'
            : transaction.categoryName ?? 'Giao dịch';
    final subtitle = isTransfer
        ? '${transaction.walletName ?? 'Ví'} → ${transaction.toWalletName ?? 'Ví nhận'}'
        : '${transaction.categoryName ?? 'Không danh mục'} · ${transaction.walletName ?? 'Ví'}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Icon(icon, size: 19),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$subtitle · ${transaction.transactionDate}', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text('${isIncome ? '+' : isTransfer ? '↔ ' : '−'}${formatVnd(transaction.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}
