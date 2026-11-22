import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

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
  Widget build(BuildContext context) => SizedBox(
        height: 190,
        width: double.infinity,
        child: CustomPaint(
          painter: _CashFlowPainter(
            points: points,
            income: Theme.of(context).colorScheme.primary,
            expense: Theme.of(context).colorScheme.error,
            grid: Theme.of(context).colorScheme.outlineVariant,
            labels: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

class _CashFlowPainter extends CustomPainter {
  const _CashFlowPainter({required this.points, required this.income, required this.expense, required this.grid, required this.labels});
  final List<CashFlowPoint> points;
  final Color income;
  final Color expense;
  final Color grid;
  final Color labels;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0, bottom = 24.0, top = 8.0, right = 4.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left - right;
    final maxValue = points.fold<int>(0, (max, point) => math.max(max, math.max(point.income, point.expense)));
    final scale = maxValue == 0 ? 1.0 : maxValue.toDouble();
    final linePaint = Paint()..color = grid.withValues(alpha: .6)..strokeWidth = 1;
    final textStyle = TextStyle(color: labels, fontSize: 10);
    final monthStyle = TextStyle(color: labels, fontSize: 10);
    for (var i = 0; i < 3; i++) {
      final y = top + chartHeight * i / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), linePaint);
    }
    if (points.isEmpty) return;
    final groupWidth = chartWidth / points.length;
    final barWidth = math.min(13.0, groupWidth * .24);
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final centerX = left + groupWidth * (i + .5);
      final incomeHeight = chartHeight * point.income / scale;
      final expenseHeight = chartHeight * point.expense / scale;
      final incomeRect = Rect.fromLTWH(centerX - barWidth - 1, top + chartHeight - incomeHeight, barWidth, incomeHeight);
      final expenseRect = Rect.fromLTWH(centerX + 1, top + chartHeight - expenseHeight, barWidth, expenseHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(incomeRect, const Radius.circular(3)), Paint()..color = income);
      canvas.drawRRect(RRect.fromRectAndRadius(expenseRect, const Radius.circular(3)), Paint()..color = expense);
      final tp = TextPainter(text: TextSpan(text: point.month, style: monthStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, size.height - bottom + 5));
    }
    if (maxValue > 0) {
      final label = maxValue >= 1000000 ? '${(maxValue / 1000000).round()}tr' : maxValue >= 1000 ? '${(maxValue / 1000).round()}k' : '$maxValue';
      final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width - tp.width - right, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) => points != oldDelegate.points || income != oldDelegate.income || expense != oldDelegate.expense;
}

class ExpenseDonutChart extends StatelessWidget {
  const ExpenseDonutChart({required this.slices, super.key});
  final List<ExpenseSlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.amount);
    return SizedBox(
      width: 150,
      height: 150,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices, total: total, track: Theme.of(context).colorScheme.surfaceContainerHighest),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(slices.isEmpty ? '—' : '${slices.length}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('danh mục', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
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
    final trackPaint = Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = 16;
    canvas.drawArc(rect.deflate(8), -math.pi / 2, 2 * math.pi, false, trackPaint);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = 2 * math.pi * slice.amount / total;
      canvas.drawArc(rect.deflate(8), start, sweep, false, Paint()..color = slice.color..style = PaintingStyle.stroke..strokeWidth = 16..strokeCap = StrokeCap.round);
      start += sweep + .025;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => slices != oldDelegate.slices || total != oldDelegate.total || track != oldDelegate.track;
}
