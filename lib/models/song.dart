import '../models/activity.dart' show SkillCategory;

/// One section of a song — a verse, a chorus, a repeated line.
///
/// A part carries its words and how long it runs *relative to the rest of the
/// song*, not an absolute timestamp. Timestamps belong to a particular
/// recording, and the same rhyme on YouTube exists in a hundred recordings at
/// a hundred different tempos; a stored "0:42" would be wrong for all but one
/// of them. [weight] survives that — see [SongSegmenter].
class SongPart {
  /// What to call this section on screen: 'Verse 1', 'Chorus', 'Ending'.
  final String label;

  /// The words, one entry per sung line.
  final List<String> lines;

  /// How much of the song this part occupies, relative to the other parts.
  ///
  /// Defaults to the line count, which tracks real section length closely
  /// enough for a nursery rhyme, where every line is about a bar long.
  final double? weightOverride;

  const SongPart({
    required this.label,
    required this.lines,
    this.weightOverride,
  });

  double get weight => weightOverride ?? lines.length.toDouble();

  String get text => lines.join('\n');
}

/// A song a parent can sing with their child, and — when they want the tune —
/// play from YouTube one section at a time.
class Song {
  final String id;
  final String title;

  /// What to search YouTube for. Kept separate from [title] so the catalogue
  /// can say 'Twinkle Twinkle Little Star' while searching for something that
  /// actually surfaces a children's recording.
  final String searchQuery;

  /// A sentence on why this song is worth singing at this age.
  final String why;

  final SkillCategory skillCategory;
  final int ageBandMinWeeks;
  final int ageBandMaxWeeks;

  final List<SongPart> parts;

  const Song({
    required this.id,
    required this.title,
    required this.searchQuery,
    required this.why,
    required this.skillCategory,
    required this.ageBandMinWeeks,
    required this.ageBandMaxWeeks,
    required this.parts,
  });

  bool matchesAge(int ageInWeeks) =>
      ageInWeeks >= ageBandMinWeeks && ageInWeeks < ageBandMaxWeeks;

  /// Every line in order, for the "just show me the words" view.
  List<String> get allLines => [for (final p in parts) ...p.lines];
}

/// A [SongPart] placed against a real recording's clock.
class TimedPart {
  final SongPart part;
  final Duration start;
  final Duration end;

  const TimedPart({
    required this.part,
    required this.start,
    required this.end,
  });

  Duration get length => end - start;

  /// Whether [position] falls inside this part. The end is exclusive so two
  /// adjacent parts never both claim the same instant.
  bool contains(Duration position) => position >= start && position < end;
}

/// Splits a recording into parts without ever touching its audio.
///
/// The obvious way to find where a chorus starts is to analyse the waveform,
/// and YouTube's terms do not permit downloading the audio to do that. What is
/// available is the one number the embedded player will tell us: how long the
/// video runs. Distributing the known section structure across that duration,
/// weighted by section length, puts each part within a second or two of its
/// real position for a nursery rhyme — close enough to loop a verse, and it
/// costs no network, no processing, and no hand-timing of individual videos.
class SongSegmenter {
  SongSegmenter._();

  /// Fraction of the runtime a typical children's upload spends on a title
  /// card or spoken intro before the singing starts.
  static const double _introFraction = 0.06;

  /// Splits [total] across [parts] in proportion to their weights.
  ///
  /// Returns an empty list for an empty part list or a non-positive duration,
  /// so a caller that has not yet heard back from the player renders nothing
  /// rather than a row of zero-length chips.
  static List<TimedPart> split(Duration total, List<SongPart> parts) {
    if (parts.isEmpty || total <= Duration.zero) return const [];

    final totalWeight = parts.fold<double>(0, (sum, p) => sum + p.weight);
    if (totalWeight <= 0) return const [];

    final intro = total * _introFraction;
    final singing = total - intro;

    final timed = <TimedPart>[];
    var cursor = intro;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      // The last part is pinned to the end rather than accumulated, so
      // rounding never leaves a gap or overshoots the video.
      final end = i == parts.length - 1
          ? total
          : cursor + singing * (part.weight / totalWeight);
      timed.add(TimedPart(part: part, start: cursor, end: end));
      cursor = end;
    }
    return timed;
  }

  /// Splits [total] into [count] equal parts labelled 'Part 1', 'Part 2'…
  ///
  /// For a video a parent pasted in themselves, where no structure is known.
  static List<TimedPart> splitEvenly(Duration total, int count) {
    if (count <= 0) return const [];
    return split(
      total,
      [
        for (var i = 1; i <= count; i++)
          SongPart(label: 'Part $i', lines: const [], weightOverride: 1),
      ],
    );
  }
}
