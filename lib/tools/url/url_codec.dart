import '../../core/result.dart';

/// [fullUrl] keeps the URL structure (: / ? # & =) intact, like encodeURI.
/// Otherwise everything is encoded, for a single value such as a query
/// parameter (encodeURIComponent).
Result<String, String> encodeUrl(String text, {bool fullUrl = false}) {
  try {
    return Ok(fullUrl ? Uri.encodeFull(text) : Uri.encodeComponent(text));
  } catch (_) {
    return const Err(
      'O texto contém um caractere Unicode incompleto e não pode ser codificado.',
    );
  }
}

final _badPercent = RegExp(r'%(?![0-9a-fA-F]{2})');
final _percentRun = RegExp(r'(?:%[0-9a-fA-F]{2})+');

/// [plusAsSpace]: HTML forms (application/x-www-form-urlencoded) encode
/// spaces as "+".
Result<String, String> decodeUrl(String text, {bool plusAsSpace = false}) {
  final source = plusAsSpace ? text.replaceAll('+', ' ') : text;
  try {
    return Ok(Uri.decodeComponent(source));
  } catch (_) {
    final badPercent = _badPercent.firstMatch(source);
    if (badPercent != null) {
      return Err(
        '"%" inválido na posição ${badPercent.start + 1}: depois de % devem vir '
        'dois dígitos hexadecimais (ex.: %20).',
      );
    }
    for (final run in _percentRun.allMatches(source)) {
      try {
        Uri.decodeComponent(run.group(0)!);
      } catch (_) {
        return Err(
          'Sequência "${run.group(0)}" na posição ${run.start + 1} não forma '
          'um caractere UTF-8 válido.',
        );
      }
    }
    return const Err('Texto percent-encoded inválido.');
  }
}
