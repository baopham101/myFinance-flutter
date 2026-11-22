import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/formatters/money.dart';

class CashFlowPoint {
  const CashFlowPoint({required this.month, required this.income, required this.expense});
  final String month;
  final int income;
  final int expense;
}

class ExpenseSlice {
  const ExpenseSlice({required this.label, required this.amount, required this.color});
  final String label;
  final int amount;
  final Color color;
}

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({required this.points, super.key});
  final List<CashFlowPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(0, (max, p) => math.max(max, math.max(p.income, p.expense)));
    final hasData = points.isNotEmpty && maxValue > 0;

    return Column(
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: CustomPaint(
            painter: _CashFlowPainter(
              points: points,
              income: Theme.of(context).colorScheme.primary,
              expense: Theme.of(context).colorScheme.error,
              grid: Theme.of(context).colorScheme.outlineVariant,
              labels: Theme.of(context).colorScheme.onSurfaceVariant,
              maxValue: maxValue,
            ),
          ),
        ),
        if (!hasData)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Chưa có dữ liệu thu chi 6 tháng gần đây',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  const _CashFlowPainter({
    required this.points,
    required this.income,
    required this.expense,
    required this.grid,
    required this.labels,
    required this.maxValue,
  });

  final List<CashFlowPoint> points;
  final Color income;
  final Color expense;
  final Color grid;
  final Color labels;
  final int maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 38.0;
    const rightPadding = 8.0;
    const topPadding = 16.0;
    const bottomPadding = 24.0;

    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width - leftPadding - rightPadding;

    final scale = maxValue == 0 ? 1.0 : maxValue.toDouble();
    final linePaint = Paint()
      ..color = grid.withValues(alpha: .5)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: labels, fontSize: 10, fontWeight: FontWeight.w500);

    // Y-axis grid lines and labels (3 steps: 0, max/2, max)
    final ySteps = [1.0, 0.5, 0.0];
    for (final step in ySteps) {
      final y = topPadding + chartHeight * (1.0 - step);
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), linePaint);

      final val = maxValue * step;
      final labelText = step == 0.0 ? '0' : compactVnd(val);
      final tp = TextPainter(
        text: TextSpan(text: labelText, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 6, y - tp.height / 2));
    }

    if (points.isEmpty) return;

    final groupWidth = chartWidth / points.length;
    final barWidth = math.min(13.0, math.max(5.0, groupWidth * .24));

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final centerX = leftPadding + groupWidth * (i + .5);

      if (maxValue > 0) {
        final incomeHeight = chartHeight * (point.income / scale);
        final expenseHeight = chartHeight * (point.expense / scale);

        if (point.income > 0) {
          final incomeRect = Rect.fromLTWH(
            centerX - barWidth - 1.5,
            topPadding + chartHeight - incomeHeight,
            barWidth,
            incomeHeight,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(incomeRect, const Radius.circular(5)),
            Paint()..color = income,
          );
        }

        if (point.expense > 0) {
          final expenseRect = Rect.fromLTWH(
            centerX + 1.5,
            topPadding + chartHeight - expenseHeight,
            barWidth,
            expenseHeight,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(expenseRect, const Radius.circular(5)),
            Paint()..color = expense,
          );
        }
      }

      // Format month label e.g., "11月" -> "T11" or keep if clean
      final monthClean = point.month.replaceAll('月', '');
      final displayMonth = int.tryParse(monthClean) != null ? 'T$monthClean' : point.month;

      final tp = TextPainter(
        text: TextSpan(text: displayMonth, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, size.height - bottomPadding + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) =>
      points != oldDelegate.points ||
      income != oldDelegate.income ||
      expense != oldDelegate.expense ||
      maxValue != oldDelegate.maxValue;
}

class ExpenseDonutChart extends StatelessWidget {
  const ExpenseDonutChart({required this.slices, this.size = 130.0, super.key});
  final List<ExpenseSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.amount);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          total: total,
          track: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slices.isEmpty ? '0' : '${slices.length}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'danh mục',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.total, required this.track});
  final List<ExpenseSlice> slices;
  final int total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 14.0;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect.deflate(strokeWidth / 2 + 2), -math.pi / 2, 2 * math.pi, false, trackPaint);
    if (total == 0) return;

    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = 2 * math.pi * slice.amount / total;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2 + 2),
        start,
        sweep,
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep + .03;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      slices != oldDelegate.slices || total != oldDelegate.total || track != oldDelegate.track;
}
