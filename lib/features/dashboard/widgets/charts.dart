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

class CashFlowChart extends StatefulWidget {
  const CashFlowChart({required this.points, super.key});
  final List<CashFlowPoint> points;

  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _animController;
  late final List<Animation<double>> _barAnimations;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _barAnimations = List.generate(
      widget.points.length,
      (i) => CurvedAnimation(
        parent: _animController,
        curve: Interval((i * 0.1).clamp(0.0, 0.8), 1.0, curve: Curves.easeOutCubic),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final media = MediaQuery.of(context);
      _reduceMotion = media.disableAnimations;
      if (!_reduceMotion) {
        _animController.forward();
      } else {
        _animController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CashFlowChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _animController.forward(from: 0);
    }
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final size = constraints.biggest;
    if (widget.points.isEmpty) return;

    const leftPadding = 38.0;
    const rightPadding = 8.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final groupWidth = chartWidth / widget.points.length;
    final dx = details.localPosition.dx;

    final relativeX = dx - leftPadding;
    if (relativeX < 0 || relativeX > chartWidth) {
      setState(() => _selectedIndex = null);
      return;
    }

    final index = (relativeX / groupWidth).floor().clamp(0, widget.points.length - 1);
    setState(() => _selectedIndex = _selectedIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.points.fold<int>(0, (max, p) => math.max(max, math.max(p.income, p.expense)));
    final hasData = widget.points.isNotEmpty && maxValue > 0;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (details) => _onTapDown(details, constraints),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(
                  painter: _CashFlowPainter(
                    points: widget.points,
                    income: Theme.of(context).colorScheme.primary,
                    expense: Theme.of(context).colorScheme.error,
                    grid: Theme.of(context).colorScheme.outlineVariant,
                    labels: Theme.of(context).colorScheme.onSurfaceVariant,
                    maxValue: maxValue,
                    selectedIndex: _selectedIndex,
                    barAnimations: _reduceMotion
                        ? List.generate(widget.points.length, (_) => const AlwaysStoppedAnimation(1.0))
                        : _barAnimations,
                    context: context,
                  ),
                ),
              ),
            );
          },
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
    required this.selectedIndex,
    required this.barAnimations,
    required this.context,
  });

  final List<CashFlowPoint> points;
  final Color income;
  final Color expense;
  final Color grid;
  final Color labels;
  final int maxValue;
  final int? selectedIndex;
  final List<Animation<double>> barAnimations;
  final BuildContext context;

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
      final anim = barAnimations[i].value;

      if (maxValue > 0) {
        final incomeHeight = chartHeight * (point.income / scale) * anim;
        final expenseHeight = chartHeight * (point.expense / scale) * anim;

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

      // Selected tooltip overlay
      if (selectedIndex == i) {
        final overlayPaint = Paint()..color = Theme.of(context).colorScheme.surface.withValues(alpha: .95);
        final overlayRect = Rect.fromLTWH(
          leftPadding,
          topPadding,
          chartWidth,
          chartHeight,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(overlayRect, const Radius.circular(8)), overlayPaint);

        // Show values for selected month
        final selectedPoint = points[i];
        final valueStyle = TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600);
        final incomeText = 'Thu: ${compactVnd(selectedPoint.income)}';
        final expenseText = 'Chi: ${compactVnd(selectedPoint.expense)}';

        final incomeTp = TextPainter(
          text: TextSpan(text: incomeText, style: valueStyle.copyWith(color: income)),
          textDirection: TextDirection.ltr,
        )..layout();
        final expenseTp = TextPainter(
          text: TextSpan(text: expenseText, style: valueStyle.copyWith(color: expense)),
          textDirection: TextDirection.ltr,
        )..layout();

        final tooltipY = topPadding + 16;
        final tooltipX = centerX - math.max(incomeTp.width, expenseTp.width) / 2;

        incomeTp.paint(canvas, Offset(tooltipX, tooltipY));
        expenseTp.paint(canvas, Offset(tooltipX, tooltipY + incomeTp.height + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) =>
      points != oldDelegate.points ||
      income != oldDelegate.income ||
      expense != oldDelegate.expense ||
      maxValue != oldDelegate.maxValue ||
      selectedIndex != oldDelegate.selectedIndex ||
      barAnimations != oldDelegate.barAnimations ||
      context != oldDelegate.context;
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