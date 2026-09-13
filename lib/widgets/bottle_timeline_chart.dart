import 'package:flutter/material.dart';

import '../models/bottle.dart';

class BottleTimelineChart extends StatelessWidget {
  final List<Bottle> bottles;

  const BottleTimelineChart({
    super.key,
    required this.bottles,
  });

  @override
  Widget build(BuildContext context) {
    if (bottles.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final sortedBottles = [...bottles]
      ..sort(
        (a, b) => a.feedingStartedAt.compareTo(
          b.feedingStartedAt,
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartLegend(),
        const SizedBox(height: 12),
        Expanded(
          child: _BottleTimelineChartView(
            bottles: sortedBottles,
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _LegendItem(
          color: theme.colorScheme.primary,
          label: 'Temps de prise',
        ),
        const SizedBox(width: 20),
        const _LegendItem(
          color: Colors.red,
          label: 'Temps de rot',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BottleTimelineChartView extends StatefulWidget {
  final List<Bottle> bottles;

  const _BottleTimelineChartView({
    required this.bottles,
  });

  @override
  State<_BottleTimelineChartView> createState() =>
      _BottleTimelineChartViewState();
}

class _BottleTimelineChartViewState
    extends State<_BottleTimelineChartView> {
  int? _selectedIndex;

  static const double _leftPadding = 58;
  static const double _rightPadding = 80;
  static const double _topPadding = 32;
  static const double _bottomPadding = 42;

  static const double _rowHeight = 56;
  static const double _barHeight = 18;

  static const double _minimumChartWidth = 1100;

  static const int _startHour = 6;
  static const int _endHour = 24;

  @override
  Widget build(BuildContext context) {
    final height =
        _topPadding +
        widget.bottles.length * _rowHeight +
        _bottomPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth <
                _minimumChartWidth
            ? _minimumChartWidth
            : constraints.maxWidth;

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                _handleTap(
                  details.localPosition,
                  chartWidth,
                );
              },
              child: CustomPaint(
                size: Size(
                  chartWidth,
                  height,
                ),
                painter: _BottleTimelinePainter(
                  bottles: widget.bottles,
                  selectedIndex: _selectedIndex,
                  leftPadding: _leftPadding,
                  rightPadding: _rightPadding,
                  topPadding: _topPadding,
                  bottomPadding: _bottomPadding,
                  rowHeight: _rowHeight,
                  barHeight: _barHeight,
                  startHour: _startHour,
                  endHour: _endHour,
                  theme: Theme.of(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(
    Offset position,
    double width,
  ) {
    final y = position.dy - _topPadding;

    if (y < 0) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    final index = (y / _rowHeight).floor();

    if (index < 0 || index >= widget.bottles.length) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    final bottle = widget.bottles[index];

    final chartWidth =
        width - _leftPadding - _rightPadding;

    final totalMinutes =
        (_endHour - _startHour) * 60;

    final startMinutes =
        _minutesSinceMidnight(
      bottle.feedingStartedAt,
    );

    final x =
        _leftPadding +
        ((startMinutes - _startHour * 60) /
                totalMinutes) *
            chartWidth;

    final feedingDuration =
        bottle.feedingDuration?.inSeconds ?? 0;

    final feedingWidth =
        (feedingDuration / 60) /
            totalMinutes *
            chartWidth;

    final safeFeedingWidth =
        feedingWidth.clamp(4.0, chartWidth);

    final isInsideX =
        position.dx >= x - 10 &&
        position.dx <=
            x + safeFeedingWidth + 10;

    if (!isInsideX) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    setState(() {
      _selectedIndex =
          _selectedIndex == index ? null : index;
    });

    _showBottleDetails(bottle);
  }

  void _showBottleDetails(Bottle bottle) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Biberon',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'Heure',
                  value: _formatTime(
                    bottle.feedingStartedAt,
                  ),
                ),
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: 'Temps de prise',
                  value: _formatDuration(
                    bottle.feedingDuration,
                  ),
                ),
                _DetailRow(
                  icon: Icons.air,
                  label: 'Temps de rot',
                  value: _formatDuration(
                    bottle.burpingDuration,
                  ),
                ),
                _DetailRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Volume',
                  value: _formatVolume(bottle),
                ),
                if (bottle.type != null)
                  _DetailRow(
                    icon: Icons.local_drink_outlined,
                    label: 'Type',
                    value: _formatType(
                      bottle.type!,
                    ),
                  ),
                if (bottle.notes != null &&
                    bottle.notes!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.notes,
                    label: 'Notes',
                    value: bottle.notes!,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  int _minutesSinceMidnight(
    DateTime dateTime,
  ) {
    return dateTime.hour * 60 +
        dateTime.minute;
  }

  String _formatTime(
    DateTime dateTime,
  ) {
    final hour =
        dateTime.hour.toString().padLeft(2, '0');

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(
    Duration? duration,
  ) {
    if (duration == null) {
      return '--';
    }

    final minutes = duration.inMinutes;
    final seconds =
        duration.inSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    }

    if (seconds == 0) {
      return '${minutes}min';
    }

    return '${minutes}min ${seconds}s';
  }

  String _formatVolume(
    Bottle bottle,
  ) {
    if (bottle.volume == null) {
      return '--';
    }

    final volume = bottle.volume!;

    final formatted =
        volume % 1 == 0
            ? volume.toInt().toString()
            : volume.toStringAsFixed(1);

    final unit = switch (bottle.volumeUnit) {
      VolumeUnit.ml => 'ml',
      VolumeUnit.oz => 'oz',
      null => '',
    };

    return '$formatted $unit';
  }

  String _formatType(
    BottleType type,
  ) {
    return switch (type) {
      BottleType.breastMilk => 'Lait maternel',
      BottleType.formula => 'Lait artificiel',
      BottleType.other => 'Autre',
    };
  }
}

class _BottleTimelinePainter
    extends CustomPainter {
  final List<Bottle> bottles;
  final int? selectedIndex;

  final double leftPadding;
  final double rightPadding;
  final double topPadding;
  final double bottomPadding;

  final double rowHeight;
  final double barHeight;

  final int startHour;
  final int endHour;

  final ThemeData theme;

  _BottleTimelinePainter({
    required this.bottles,
    required this.selectedIndex,
    required this.leftPadding,
    required this.rightPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.rowHeight,
    required this.barHeight,
    required this.startHour,
    required this.endHour,
    required this.theme,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final chartWidth =
        size.width -
        leftPadding -
        rightPadding;

    final chartHeight =
        size.height -
        topPadding -
        bottomPadding;

    _drawBackground(
      canvas,
      size,
    );

    _drawTimeGrid(
      canvas,
      chartWidth,
      chartHeight,
    );

    _drawBottles(
      canvas,
      chartWidth,
    );

    _drawTimeLabels(
      canvas,
      size,
      chartWidth,
    );
  }

  void _drawBackground(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = theme.colorScheme.surface;

    canvas.drawRect(
      Offset.zero & size,
      paint,
    );
  }

  void _drawTimeGrid(
    Canvas canvas,
    double chartWidth,
    double chartHeight,
  ) {
    final verticalPaint = Paint()
      ..color =
          theme.colorScheme.outlineVariant
      ..strokeWidth = 1;

    final horizontalPaint = Paint()
      ..color =
          theme.colorScheme.outlineVariant
      ..strokeWidth = 0.5;

    final totalMinutes =
        (endHour - startHour) * 60;

    for (int hour = startHour;
        hour <= endHour;
        hour++) {
      final minutesFromStart =
          (hour - startHour) * 60;

      final x =
          leftPadding +
          (minutesFromStart /
                  totalMinutes) *
              chartWidth;

      canvas.drawLine(
        Offset(x, topPadding),
        Offset(
          x,
          topPadding + chartHeight,
        ),
        verticalPaint,
      );
    }

    for (int i = 0;
        i <= bottles.length;
        i++) {
      final y =
          topPadding + i * rowHeight;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(
          leftPadding + chartWidth,
          y,
        ),
        horizontalPaint,
      );
    }
  }

  void _drawBottles(
    Canvas canvas,
    double chartWidth,
  ) {
    final totalMinutes =
        (endHour - startHour) * 60;

    for (int index = 0;
        index < bottles.length;
        index++) {
      final bottle = bottles[index];

      final startMinutes =
          bottle.feedingStartedAt.hour * 60 +
          bottle.feedingStartedAt.minute;

      final rowTop =
          topPadding +
          index * rowHeight;

      final centerY =
          rowTop + rowHeight / 2;

      final x =
          leftPadding +
          ((startMinutes -
                      startHour * 60) /
                  totalMinutes) *
              chartWidth;

      final feedingDuration =
          bottle.feedingDuration?.inSeconds ??
              0;

      final feedingWidth =
          (feedingDuration / 60) /
              totalMinutes *
              chartWidth;

      final safeFeedingWidth =
          feedingWidth.clamp(
        4.0,
        chartWidth,
      );

      final isSelected =
          selectedIndex == index;

      _drawFeedingBar(
        canvas,
        x,
        centerY,
        safeFeedingWidth,
        isSelected,
      );

      _drawBurpingBar(
        canvas,
        bottle,
        x,
        centerY,
        safeFeedingWidth,
        chartWidth,
      );

      _drawVolume(
        canvas,
        bottle,
        x,
        centerY,
        safeFeedingWidth,
        chartWidth,
      );

      _drawStartTime(
        canvas,
        bottle,
        rowTop,
      );
    }
  }

  void _drawFeedingBar(
    Canvas canvas,
    double x,
    double centerY,
    double width,
    bool selected,
  ) {
    // 🔵 Temps de prise
    final paint = Paint()
      ..color = theme.colorScheme.primary;

    if (selected) {
      paint.color =
          theme.colorScheme.primary.withValues(
        alpha: 0.65,
      );
    }

    final rect =
        RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x,
        centerY - barHeight / 2,
        width,
        barHeight,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      rect,
      paint,
    );
  }

  void _drawBurpingBar(
    Canvas canvas,
    Bottle bottle,
    double x,
    double centerY,
    double feedingWidth,
    double chartWidth,
  ) {
    final duration =
        bottle.burpingDuration;

    if (duration == null ||
        duration.inSeconds <= 0) {
      return;
    }

    final totalMinutes =
        (endHour - startHour) * 60;

    final burpingWidth =
        (duration.inSeconds / 60) /
            totalMinutes *
            chartWidth;

    final safeWidth =
        burpingWidth.clamp(
      4.0,
      chartWidth,
    );

    // 🔴 Temps de rot
    final paint = Paint()
      ..color = Colors.red;

    final rect =
        RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x + feedingWidth,
        centerY - barHeight / 2,
        safeWidth,
        barHeight,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      rect,
      paint,
    );
  }

  void _drawVolume(
    Canvas canvas,
    Bottle bottle,
    double x,
    double centerY,
    double feedingWidth,
    double chartWidth,
  ) {
    if (bottle.volume == null) {
      return;
    }

    final volume = bottle.volume!;

    final formatted =
        volume % 1 == 0
            ? volume.toInt().toString()
            : volume.toStringAsFixed(1);

    final unit = switch (bottle.volumeUnit) {
      VolumeUnit.ml => 'ml',
      VolumeUnit.oz => 'oz',
      null => '',
    };

    final text = '$formatted $unit';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.textTheme.labelSmall
            ?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    var textX =
        x + feedingWidth + 8;

    final chartEnd =
        leftPadding + chartWidth;

    if (textX + textPainter.width >
        chartEnd) {
      textX =
          x - textPainter.width - 8;
    }

    if (textX < leftPadding) {
      textX =
          x + feedingWidth + 8;
    }

    textPainter.paint(
      canvas,
      Offset(
        textX,
        centerY -
            textPainter.height / 2,
      ),
    );
  }

  void _drawStartTime(
    Canvas canvas,
    Bottle bottle,
    double rowTop,
  ) {
    final time =
        '${bottle.feedingStartedAt.hour.toString().padLeft(2, '0')}:'
        '${bottle.feedingStartedAt.minute.toString().padLeft(2, '0')}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: time,
        style: theme.textTheme.labelSmall
            ?.copyWith(
          fontWeight: FontWeight.bold,
          color:
              theme.colorScheme.onSurfaceVariant,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        0,
        rowTop +
            rowHeight / 2 -
            textPainter.height / 2,
      ),
    );
  }

  void _drawTimeLabels(
    Canvas canvas,
    Size size,
    double chartWidth,
  ) {
    final totalMinutes =
        (endHour - startHour) * 60;

    for (int hour = startHour;
        hour <= endHour;
        hour++) {
      final minutesFromStart =
          (hour - startHour) * 60;

      final x =
          leftPadding +
          (minutesFromStart /
                  totalMinutes) *
              chartWidth;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$hour:00',
          style: theme.textTheme.labelSmall
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      var textX =
          x - textPainter.width / 2;

      if (hour == startHour) {
        textX = x;
      }

      if (hour == endHour) {
        textX =
            x - textPainter.width;
      }

      textPainter.paint(
        canvas,
        Offset(
          textX,
          size.height -
              bottomPadding +
              8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _BottleTimelinePainter
        oldDelegate,
  ) {
    return oldDelegate.bottles != bottles ||
        oldDelegate.selectedIndex !=
            selectedIndex ||
        oldDelegate.theme != theme;
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

