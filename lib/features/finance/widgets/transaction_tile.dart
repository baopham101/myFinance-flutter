import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/dates.dart';
import '../../../core/formatters/money.dart';
import '../data/models.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, this.showDate = true, super.key});
  final FinanceTransaction transaction;
  final VoidCallback? onTap;
  final bool showDate;

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
    final sign = isIncome ? '+' : isTransfer ? '' : '−';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    showDate ? '$subtitle · ${formatDate(transaction.transactionDate)}' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sign${formatVnd(transaction.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                if (isTransfer) ...[
                  const SizedBox(height: 3),
                  Text(
                    'chuyển khoản',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
