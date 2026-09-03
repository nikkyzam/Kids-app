import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../data/database_helper.dart';
import '../../models/child_profile.dart';
import '../../models/growth_measurement.dart';
import '../../providers/profile_provider.dart';
import '../../services/who_growth_standards.dart';
import '../../theme/app_theme.dart';
import '../../utils/clock.dart';

class GrowthTrackerScreen extends StatefulWidget {
  final int profileId;

  const GrowthTrackerScreen({super.key, required this.profileId});

  @override
  State<GrowthTrackerScreen> createState() => _GrowthTrackerScreenState();
}

class _GrowthTrackerScreenState extends State<GrowthTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GrowthMeasurement> _measurements = [];
  bool _useImperial = false;
  bool _isLoading = true;

  static const _metrics = GrowthMetric.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _metrics.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadMeasurements();
      }
    });
    _loadMeasurements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  GrowthMetric get _currentMetric => _metrics[_tabController.index];

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance
        .getGrowthMeasurements(widget.profileId, _currentMetric);
    if (mounted) {
      setState(() {
        _measurements = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMeasurement(GrowthMeasurement m) async {
    if (m.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete measurement?'),
        content: const Text('This measurement will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteGrowthMeasurement(m.id!);
      await _loadMeasurements();
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMeasurementSheet(
        profileId: widget.profileId,
        metric: _currentMetric,
        useImperial: _useImperial,
        onSaved: _loadMeasurements,
      ),
    );
  }

  Color _metricColor(GrowthMetric metric) {
    switch (metric) {
      case GrowthMetric.weight:
        return AppTheme.primary;
      case GrowthMetric.height:
        return AppTheme.grossMotorColor;
      case GrowthMetric.headCircumference:
        return AppTheme.cognitiveColor;
    }
  }

  double _displayValue(double storedValue, GrowthMetric metric) {
    if (!_useImperial) return storedValue;
    if (metric == GrowthMetric.weight) return storedValue * 2.20462;
    return storedValue / 2.54;
  }

  String _unit(GrowthMetric metric) =>
      _useImperial ? metric.unitImperial : metric.unit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Tracker'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _useImperial = !_useImperial),
            child: Text(
              _useImperial ? 'lbs/in' : 'kg/cm',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddSheet,
            tooltip: 'Add measurement',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weight'),
            Tab(text: 'Height'),
            Tab(text: 'Head'),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _metrics.map((metric) {
          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _MetricTabBody(
                  measurements: _measurements,
                  metric: metric,
                  useImperial: _useImperial,
                  displayValue: (v) => _displayValue(v, metric),
                  unit: _unit(metric),
                  color: _metricColor(metric),
                  onDelete: _deleteMeasurement,
                  profile: context
                      .watch<ProfileProvider>()
                      .profiles
                      .where((p) => p.id == widget.profileId)
                      .firstOrNull,
                );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MetricTabBody extends StatelessWidget {
  final List<GrowthMeasurement> measurements;
  final GrowthMetric metric;
  final bool useImperial;
  final double Function(double) displayValue;
  final String unit;
  final Color color;
  final Future<void> Function(GrowthMeasurement) onDelete;
  final ChildProfile? profile;

  const _MetricTabBody({
    required this.measurements,
    required this.metric,
    required this.useImperial,
    required this.displayValue,
    required this.unit,
    required this.color,
    required this.onDelete,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...measurements]
      ..sort((a, b) => a.measuredOnDate.compareTo(b.measuredOnDate));
    final reversed = sorted.reversed.toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _GrowthChart(
          measurements: sorted,
          useImperial: useImperial,
          color: color,
          metric: metric,
          profile: profile,
        ),
        if (sorted.isNotEmpty)
          _PercentileNote(
            metric: metric,
            profile: profile,
            latest: sorted.last,
          ),
        if (measurements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  metric == GrowthMetric.weight
                      ? Icons.monitor_weight_outlined
                      : Icons.straighten_outlined,
                  size: 56,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No measurements yet',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to log your first measurement',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...reversed.map((m) {
            final val = displayValue(m.value);
            final formatted = val == val.roundToDouble()
                ? val.toInt().toString()
                : val.toStringAsFixed(1);
            final dateStr = DateFormat('MMM d, yyyy').format(m.measuredOnDate);
            final subtitle = m.notes != null && m.notes!.isNotEmpty
                ? '$dateStr · ${m.notes}'
                : dateStr;

            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  formatted,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              title: Text(
                '$formatted $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.textDark,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              trailing: IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: AppTheme.textMuted),
                onPressed: () => onDelete(m),
              ),
            );
          }),
      ],
    );
  }
}

class _GrowthChart extends StatelessWidget {
  final List<GrowthMeasurement> measurements;
  final bool useImperial;
  final Color color;
  final GrowthMetric metric;
  final ChildProfile? profile;

  const _GrowthChart({
    required this.measurements,
    required this.useImperial,
    required this.color,
    required this.metric,
    required this.profile,
  });

  /// The WHO percentile curves across the span the chart covers.
  ///
  /// Sampled rather than drawn from the monthly table directly: the chart's x
  /// axis is dates, not months, so each sample converts a date to the child's
  /// age and reads the curve there. Returns an empty list when there is no
  /// honest curve to draw — no sex recorded, or an age past the tables.
  List<_PercentileCurve> _curves(List<DateTime> span) {
    final child = profile;
    final sex = child?.sex;
    if (child == null || sex == null || span.length < 2) return const [];

    const samples = 48;
    final from = span.first.millisecondsSinceEpoch;
    final to = span.last.millisecondsSinceEpoch;

    final curves = <_PercentileCurve>[];
    for (final percentile in WhoGrowthStandards.curvePercentiles) {
      final z = WhoGrowthStandards.zForPercentile(percentile);
      final points = <MapEntry<DateTime, double>>[];
      for (int i = 0; i <= samples; i++) {
        final at = DateTime.fromMillisecondsSinceEpoch(
            from + ((to - from) * i / samples).round());
        final months = WhoGrowthStandards.ageMonthsAt(child, at);
        final value = WhoGrowthStandards.valueAtZ(metric, sex, months, z);
        if (value != null) points.add(MapEntry(at, value));
      }
      // A curve that only covers part of the span would read as the child's
      // data falling off it, so a partial curve is not drawn at all.
      if (points.length == samples + 1) {
        curves.add(_PercentileCurve(percentile, points));
      }
    }
    return curves;
  }

  @override
  Widget build(BuildContext context) {
    if (measurements.length < 2) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Log at least 2 measurements to see the chart',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _ChartPainter(
            measurements: measurements,
            useImperial: useImperial,
            color: color,
            curves: _curves(measurements.map((m) => m.measuredOnDate).toList()),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// One WHO percentile line across the span the chart covers.
class _PercentileCurve {
  final int percentile;
  final List<MapEntry<DateTime, double>> points;

  const _PercentileCurve(this.percentile, this.points);
}

class _ChartPainter extends CustomPainter {
  final List<GrowthMeasurement> measurements;
  final bool useImperial;
  final Color color;
  final List<_PercentileCurve> curves;

  _ChartPainter({
    required this.measurements,
    required this.useImperial,
    required this.color,
    this.curves = const [],
  });

  double _toDisplay(double v, GrowthMetric m) {
    if (!useImperial) return v;
    return m == GrowthMetric.weight ? v * 2.20462 : v / 2.54;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 48.0;
    // Wider when the percentile curves are drawn, so their labels have
    // somewhere to sit that is not on top of the plot.
    final rightPad = curves.isEmpty ? 16.0 : 26.0;
    const topPad = 12.0;
    const bottomPad = 28.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final values =
        measurements.map((m) => _toDisplay(m.value, m.metric)).toList();
    // The percentile curves are inside the range on purpose: a chart scaled
    // only to the child's own numbers would put their line down the middle
    // whatever it was doing, which is the opposite of the point.
    final metric = measurements.first.metric;
    final curveValues = curves
        .expand((c) => c.points.map((p) => _toDisplay(p.value, metric)))
        .toList();
    final minVal = [...values, ...curveValues].reduce(min);
    final maxVal = [...values, ...curveValues].reduce(max);
    final valRange = (maxVal - minVal) == 0 ? 1.0 : maxVal - minVal;
    final paddedMin = minVal - valRange * 0.1;
    final paddedMax = maxVal + valRange * 0.1;
    final paddedRange = paddedMax - paddedMin;

    final dates = measurements.map((m) => m.measuredOnDate).toList();
    final minDate = dates.first.millisecondsSinceEpoch.toDouble();
    final maxDate = dates.last.millisecondsSinceEpoch.toDouble();
    final dateRange = (maxDate - minDate) == 0 ? 1.0 : maxDate - minDate;

    double xFor(DateTime d) =>
        leftPad + (d.millisecondsSinceEpoch - minDate) / dateRange * chartW;
    double yFor(double v) =>
        topPad + chartH - (v - paddedMin) / paddedRange * chartH;

    final gridPaint = Paint()
      ..color = const Color(0xFFEEF0F7)
      ..strokeWidth = 1;
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = topPad + chartH * i / gridLines;
      canvas.drawLine(
          Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
    }

    const labelStyle = TextStyle(
      fontSize: 10,
      color: AppTheme.textMuted,
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= 4; i++) {
      final v = paddedMin + paddedRange * (4 - i) / 4;
      final y = topPad + chartH * i / 4;
      final vStr =
          v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(text: vStr, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    final dateSubset = _pickDateLabels(dates);
    for (final d in dateSubset) {
      final label = DateFormat('MMM d').format(d);
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = xFor(d);
      tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartH + 6));
    }

    // Drawn before the child's line so the child's is the one in front.
    _paintCurves(canvas, metric, xFor, yFor, leftPad + chartW);

    final points = <Offset>[];
    for (int i = 0; i < measurements.length; i++) {
      points.add(Offset(xFor(dates[i]), yFor(values[i])));
    }

    final gradientPath = Path();
    gradientPath.moveTo(points.first.dx, topPad + chartH);
    gradientPath.lineTo(points.first.dx, points.first.dy);
    _addCurveToPath(gradientPath, points);
    gradientPath.lineTo(points.last.dx, topPad + chartH);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));
    canvas.drawPath(gradientPath, gradientPaint);

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    _addCurveToPath(linePath, points);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotFill);
      canvas.drawCircle(p, 4, dotStroke);
    }
  }

  void _addCurveToPath(Path path, List<Offset> points) {
    for (int i = 0; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      if (i == 0) {
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(points.last.dx, points.last.dy);
  }

  List<DateTime> _pickDateLabels(List<DateTime> dates) {
    if (dates.length <= 4) return dates;
    final result = <DateTime>[];
    final step = (dates.length - 1) / 3;
    for (int i = 0; i < 4; i++) {
      result.add(dates[(i * step).round().clamp(0, dates.length - 1)]);
    }
    return result;
  }

  void _paintCurves(
    Canvas canvas,
    GrowthMetric metric,
    double Function(DateTime) xFor,
    double Function(double) yFor,
    double rightEdge,
  ) {
    for (final curve in curves) {
      final isMedian = curve.percentile == 50;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMedian ? 1.4 : 1.0
        ..color = AppTheme.textMuted.withValues(alpha: isMedian ? 0.45 : 0.22);

      final path = Path();
      for (int i = 0; i < curve.points.length; i++) {
        final point = curve.points[i];
        final offset =
            Offset(xFor(point.key), yFor(_toDisplay(point.value, metric)));
        if (i == 0) {
          path.moveTo(offset.dx, offset.dy);
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(path, paint);

      // A small label at the right edge, so the lines are readable as
      // percentiles rather than as decoration.
      final last = curve.points.last;
      final tp = TextPainter(
        text: TextSpan(
          text: '${curve.percentile}',
          style: TextStyle(
            fontSize: 9,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted.withValues(alpha: isMedian ? 0.75 : 0.45),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(rightEdge + 2,
            yFor(_toDisplay(last.value, metric)) - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.measurements != measurements ||
      old.useImperial != useImperial ||
      old.color != color ||
      old.curves != curves;
}

class _AddMeasurementSheet extends StatefulWidget {
  final int profileId;
  final GrowthMetric metric;
  final bool useImperial;
  final VoidCallback onSaved;

  const _AddMeasurementSheet({
    required this.profileId,
    required this.metric,
    required this.useImperial,
    required this.onSaved,
  });

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = Clock.now();
  bool _saving = false;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _unit =>
      widget.useImperial ? widget.metric.unitImperial : widget.metric.unit;

  double _toStoredValue(double displayVal) {
    if (!widget.useImperial) return displayVal;
    if (widget.metric == GrowthMetric.weight) return displayVal / 2.20462;
    return displayVal * 2.54;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: Clock.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final displayVal = double.parse(_valueController.text.trim());
    final storedVal = _toStoredValue(displayVal);
    final m = GrowthMeasurement(
      profileId: widget.profileId,
      metric: widget.metric,
      value: storedVal,
      measuredOn: DateFormat('yyyy-MM-dd').format(_selectedDate),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await DatabaseHelper.instance.saveGrowthMeasurement(m);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  bool _isToday(DateTime d) {
    final now = Clock.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset + bottomPad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Log ${widget.metric.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: widget.metric.label,
                      hintText: '0.0',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Enter a valid value';
                      return null;
                    },
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _unit,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _isToday(_selectedDate)
                          ? 'Today'
                          : DateFormat('MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. measured at clinic',
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the most recent measurement sits against the WHO curves — and, when
/// it cannot say, why not.
class _PercentileNote extends StatelessWidget {
  final GrowthMetric metric;
  final ChildProfile? profile;
  final GrowthMeasurement latest;

  const _PercentileNote({
    required this.metric,
    required this.profile,
    required this.latest,
  });

  @override
  Widget build(BuildContext context) {
    final child = profile;
    if (child == null) return const SizedBox.shrink();

    if (child.sex == null) {
      return _Note(
        icon: Icons.show_chart_rounded,
        text: "Add whether ${child.name} is a girl or a boy in Settings to "
            'see the WHO growth curves — they are different for each.',
      );
    }

    final summary = WhoGrowthStandards.summaryFor(
      profile: child,
      metric: metric,
      value: latest.value,
      measuredOn: latest.measuredOnDate,
    );
    if (summary == null) {
      return const _Note(
        icon: Icons.show_chart_rounded,
        text: 'The WHO growth standards cover birth to three years, so there '
            'is no curve to compare this against.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Note(icon: Icons.show_chart_rounded, text: summary),
        // Said every time, next to the number, because this is the number most
        // likely to be read as a verdict.
        const _Note(
          icon: Icons.info_outline_rounded,
          muted: true,
          text: 'Shown for context only. Children grow along their own curves, '
              'and a percentile on its own says very little — your '
              'pediatrician is the person who can read it properly.',
        ),
        if (child.usesAdjustedAge)
          _Note(
            icon: Icons.event_rounded,
            muted: true,
            text: 'Plotted against ${child.name}\'s adjusted age, which is how '
                'these curves are read for a baby born early.',
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;

  const _Note({required this.icon, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 14,
              color: muted
                  ? AppTheme.textMuted.withValues(alpha: 0.7)
                  : AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: muted ? 11.5 : 13,
                height: 1.45,
                color: muted ? AppTheme.textMuted : AppTheme.textDark,
                fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
