import 'dart:math';
import 'dart:ui';

/// Guide strokes for tracing each capital letter, in a 0..1 box (y down).
///
/// Each stroke is a list of closely spaced points, in the direction a child
/// is taught to write it. Built from straight lines and elliptical arcs so
/// all 26 letters stay readable code rather than opaque coordinate dumps.
typedef Stroke = List<Offset>;

const double _step = 0.025;

Stroke _line(double x1, double y1, double x2, double y2) {
  final a = Offset(x1, y1), b = Offset(x2, y2);
  final n = max(2, ((b - a).distance / _step).ceil());
  return [for (var i = 0; i <= n; i++) Offset.lerp(a, b, i / n)!];
}

/// Elliptical arc. Angles in degrees, 0 = right, positive = clockwise on
/// screen (y points down), so 90 is the bottom of the ellipse.
Stroke _arc(double cx, double cy, double rx, double ry, double startDeg,
    double sweepDeg) {
  final length = sweepDeg.abs() / 360 * 2 * pi * (rx + ry) / 2;
  final n = max(4, (length / _step).ceil());
  return [
    for (var i = 0; i <= n; i++)
      () {
        final t = (startDeg + sweepDeg * i / n) * pi / 180;
        return Offset(cx + rx * cos(t), cy + ry * sin(t));
      }(),
  ];
}

/// Joins pieces into one continuous stroke.
Stroke _join(List<Stroke> parts) => [for (final p in parts) ...p];

final Map<String, List<Stroke>> letterStrokes = {
  'A': [
    _line(.5, .1, .2, .9),
    _line(.5, .1, .8, .9),
    _line(.32, .62, .68, .62)
  ],
  'B': [
    _line(.27, .1, .27, .9),
    _join([
      _line(.27, .1, .5, .1),
      _arc(.5, .3, .2, .2, -90, 180),
      _line(.5, .5, .27, .5)
    ]),
    _join([
      _line(.27, .5, .53, .5),
      _arc(.53, .7, .21, .2, -90, 180),
      _line(.53, .9, .27, .9)
    ]),
  ],
  'C': [_arc(.55, .5, .32, .4, -40, -280)],
  'D': [
    _line(.27, .1, .27, .9),
    _join([
      _line(.27, .1, .42, .1),
      _arc(.42, .5, .32, .4, -90, 180),
      _line(.42, .9, .27, .9)
    ]),
  ],
  'E': [
    _line(.3, .1, .3, .9),
    _line(.3, .1, .72, .1),
    _line(.3, .5, .65, .5),
    _line(.3, .9, .72, .9)
  ],
  'F': [_line(.3, .1, .3, .9), _line(.3, .1, .72, .1), _line(.3, .5, .65, .5)],
  'G': [
    _join([_arc(.52, .5, .32, .4, -40, -320), _line(.84, .5, .6, .5)])
  ],
  'H': [
    _line(.25, .1, .25, .9),
    _line(.75, .1, .75, .9),
    _line(.25, .5, .75, .5)
  ],
  'I': [
    _line(.5, .1, .5, .9),
    _line(.33, .1, .67, .1),
    _line(.33, .9, .67, .9)
  ],
  'J': [
    _join([_line(.65, .1, .65, .65), _arc(.45, .65, .2, .25, 0, 180)])
  ],
  'K': [
    _line(.28, .1, .28, .9),
    _line(.72, .1, .28, .56),
    _line(.43, .43, .74, .9)
  ],
  'L': [_line(.3, .1, .3, .9), _line(.3, .9, .72, .9)],
  'M': [
    _line(.2, .9, .2, .1),
    _line(.2, .1, .5, .62),
    _line(.5, .62, .8, .1),
    _line(.8, .1, .8, .9)
  ],
  'N': [
    _line(.25, .9, .25, .1),
    _line(.25, .1, .75, .9),
    _line(.75, .9, .75, .1)
  ],
  'O': [_arc(.5, .5, .32, .4, -90, -360)],
  'P': [
    _line(.28, .1, .28, .9),
    _join([
      _line(.28, .1, .5, .1),
      _arc(.5, .3, .22, .2, -90, 180),
      _line(.5, .5, .28, .5)
    ]),
  ],
  'Q': [_arc(.5, .5, .32, .4, -90, -360), _line(.58, .68, .82, .95)],
  'R': [
    _line(.28, .1, .28, .9),
    _join([
      _line(.28, .1, .5, .1),
      _arc(.5, .3, .22, .2, -90, 180),
      _line(.5, .5, .28, .5)
    ]),
    _line(.45, .5, .75, .9),
  ],
  'S': [
    _join([_arc(.5, .3, .24, .2, -20, -250), _arc(.5, .7, .25, .2, -90, 250)])
  ],
  'T': [_line(.2, .1, .8, .1), _line(.5, .1, .5, .9)],
  'U': [
    _join([
      _line(.25, .1, .25, .6),
      _arc(.5, .6, .25, .3, 180, -180),
      _line(.75, .6, .75, .1)
    ])
  ],
  'V': [_line(.2, .1, .5, .9), _line(.5, .9, .8, .1)],
  'W': [
    _line(.12, .1, .3, .9),
    _line(.3, .9, .5, .38),
    _line(.5, .38, .7, .9),
    _line(.7, .9, .88, .1)
  ],
  'X': [_line(.22, .1, .78, .9), _line(.78, .1, .22, .9)],
  'Y': [_line(.22, .1, .5, .5), _line(.78, .1, .5, .5), _line(.5, .5, .5, .9)],
  'Z': [
    _line(.22, .1, .78, .1),
    _line(.78, .1, .22, .9),
    _line(.22, .9, .78, .9)
  ],
};

/// How close (in box units) a finger must pass to count a guide point.
/// Generous: toddlers' fine motor control is still developing.
const double traceRadius = 0.08;

/// Share of all guide points that must be covered to finish a letter.
const double traceGoal = 0.85;

/// Share of *each* stroke that must be covered. Without it a short stroke
/// (A's crossbar, E's arms) could be skipped entirely and the letter still
/// pass on the long strokes alone.
const double strokeGoal = 0.75;

/// Tracks which guide points a child's finger has passed over.
class TraceProgress {
  TraceProgress(this.strokes)
      : _visited = [for (final s in strokes) List.filled(s.length, false)];

  final List<Stroke> strokes;
  final List<List<bool>> _visited;

  int get _total => strokes.fold(0, (n, s) => n + s.length);

  double get coverage {
    final done = _visited.fold(0, (n, s) => n + s.where((v) => v).length);
    return _total == 0 ? 0 : done / _total;
  }

  double strokeCoverage(int stroke) =>
      _visited[stroke].where((v) => v).length / _visited[stroke].length;

  bool get complete =>
      coverage >= traceGoal &&
      [for (var s = 0; s < strokes.length; s++) strokeCoverage(s)]
          .every((c) => c >= strokeGoal);

  bool isVisited(int stroke, int point) => _visited[stroke][point];

  /// Marks guide points near [p] (box units). Returns true if any were new.
  bool touch(Offset p) {
    var changed = false;
    for (var s = 0; s < strokes.length; s++) {
      for (var i = 0; i < strokes[s].length; i++) {
        if (!_visited[s][i] && (strokes[s][i] - p).distance <= traceRadius) {
          _visited[s][i] = true;
          changed = true;
        }
      }
    }
    return changed;
  }
}
