/// Spells a number out in English words.
///
/// The parental gate writes its whole challenge — question *and* answers — in
/// words rather than digits. Two reasons: a child who cannot yet read can
/// still recognise digits and match them, and a written-out question cannot be
/// pasted into a calculator. It only needs to cover the range the gate
/// generates, so anything outside 0–100 falls back to digits rather than
/// pretending to be a general-purpose spell-out.
class NumberWords {
  NumberWords._();

  static const _ones = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  static const _tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  static String of(int n) {
    if (n < 0 || n > 100) return '$n';
    if (n == 100) return 'one hundred';
    if (n < 20) return _ones[n];
    final tens = _tens[n ~/ 10];
    final rest = n % 10;
    return rest == 0 ? tens : '$tens-${_ones[rest]}';
  }
}
