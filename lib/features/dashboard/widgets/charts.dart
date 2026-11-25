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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final media = MediaQuery.of(context);
      if (!media.disableAnimations) {
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

  int _calculateYMax(int rawMax) {
    if (rawMax <= 0) return 100000;
    // Give ~25% headroom
    int target = (rawMax * 1.25).ceil();
    if (target < 100000) return 100000;
    if (target < 1000000) {
      return ((target + 49999) ~/ 50000) * 50000;
    } else if (target < 10000000) {
      return ((target + 499999) ~/ 500000) * 500000;
    } else {
      return ((target + 4999999) ~/ 5000000) * 5000000;
    }
  }

  String _cleanMonthLabel(String raw) {
    final clean = raw.replaceAll('月', '').replaceAll('T', '').trim();
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Chưa có dữ liệu 6 tháng gần đây',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    final rawMax = widget.points.fold<int>(0, (max, p) => math.max(max, math.max(p.income, p.expense)));
    final yMax = _calculateYMax(rawMax);
    final selected = _selectedIndex != null && _selectedIndex! < widget.points.length ? widget.points[_selectedIndex!] : null;

    final theme = Theme.of(context);
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: .3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            // Background horizontal gridlines
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 1, color: gridColor),
                  Container(height: 1, color: gridColor),
                  Container(height: 1, color: gridColor),
                  Container(height: 1.5, color: theme.colorScheme.outline.withValues(alpha: .5)), // Baseline
                ],
              ),
            ),
            // Bars & X-axis Labels
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.points.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final isSelected = _selectedIndex == i;
                  final anim = CurvedAnimation(
                    parent: _animController,
                    curve: Interval((i * 0.1).clamp(0.0, 0.8), 1.0, curve: Curves.easeOutCubic),
                  );

                  return Expanded(
                    child: Semantics(
                      label: 'Tháng ${_cleanMonthLabel(p.month)}: Thu nhập ${formatVnd(p.income)}, Chi tiêu ${formatVnd(p.expense)}',
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedIndex = isSelected ? null : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: .2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _Bar(
                                        height: p.income,
                                        color: theme.colorScheme.primary,
                                        maxValue: yMax,
                                        animation: anim,
                                      ),
                                      const SizedBox(width: 3),
                                      _Bar(
                                        height: p.expense,
                                        color: theme.colorScheme.error,
                                        maxValue: yMax,
                                        animation: anim,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _cleanMonthLabel(p.month),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (selected != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .4)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Tháng ${_cleanMonthLabel(selected.month)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Thu: ${formatVnd(selected.income)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Chi: ${formatVnd(selected.expense)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.color,
    required this.maxValue,
    required this.animation,
  });

  final int height;
  final Color color;
  final int maxValue;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final double factor = maxValue == 0 ? 0.0 : (height / maxValue).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final currentFactor = factor * animation.value;
        return FractionallySizedBox(
          heightFactor: currentFactor <= 0 ? 0.02 : currentFactor, // Min 2% indicator for non-zero or baseline
          child: Container(
            width: 8,
            decoration: BoxDecoration(
              color: height == 0 ? color.withValues(alpha: .2) : color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
        );
      },
    );
  }
}

class ExpenseDonutChart extends StatefulWidget {
  const ExpenseDonutChart({required this.slices, this.size = 130.0, super.key});
  final List<ExpenseSlice> slices;
  final double size;

  @override
  State<ExpenseDonutChart> createState() => _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart> {
  int? _selectedSlice;

  @override
  Widget build(BuildContext context) {
    final total = widget.slices.fold<int>(0, (sum, slice) => sum + slice.amount);
    final selected = _selectedSlice != null && _selectedSlice! < widget.slices.length ? widget.slices[_selectedSlice!] : null;

    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              final local = renderBox.globalToLocal(details.globalPosition);
              final center = Offset(widget.size / 2, widget.size / 2);
              final dx = local.dx - center.dx;
              final dy = local.dy - center.dy;
              final angle = math.atan2(dy, dx);
              final normalized = angle < -math.pi / 2 ? angle + 2 * math.pi : angle + math.pi / 2;
              if (normalized < 0) return;

              var accumulated = 0.0;
              for (var i = 0; i < widget.slices.length; i++) {
                final slice = widget.slices[i];
                final sweep = 2 * math.pi * slice.amount / (total == 0 ? 1 : total);
                if (accumulated <= normalized && normalized < accumulated + sweep) {
                  setState(() => _selectedSlice = _selectedSlice == i ? null : i);
                  break;
                }
                accumulated += sweep + .03;
              }
            },
            child: CustomPaint(
              painter: _DonutPainter(
                slices: widget.slices,
                total: total,
                track: Theme.of(context).colorScheme.surfaceContainerHighest,
                selectedIndex: _selectedSlice,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatVnd(selected?.amount ?? total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      selected?.label ?? 'Tổng chi',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${selected.label}: ${formatVnd(selected.amount)} (${total == 0 ? 0 : ((selected.amount / total) * 100).round()}%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.total, required this.track, required this.selectedIndex});
  final List<ExpenseSlice> slices;
  final int total;
  final Color track;
  final int? selectedIndex;

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
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = 2 * math.pi * slice.amount / total;
      final isSelected = selectedIndex == i;

      canvas.drawArc(
        rect.deflate(strokeWidth / 2 + 2),
        start,
        sweep,
        false,
        Paint()
          ..color = slice.color.withValues(alpha: isSelected ? 1.0 : 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? strokeWidth + 3 : strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep + .03;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      slices != oldDelegate.slices || total != oldDelegate.total || track != oldDelegate.track || selectedIndex != oldDelegate.selectedIndex;
}
