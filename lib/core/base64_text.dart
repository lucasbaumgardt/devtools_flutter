import 'dart:convert';

import 'result.dart';

// Text <-> Base64 through UTF-8 bytes, so accents and emoji work. Shared by
// the Base64 tool and the JWT decoder (which uses the base64url alphabet).

final _alphabet = RegExp(r'^[A-Za-z0-9+/_-]*={0,2}$');
final _invalidCharacter = RegExp(r'[^A-Za-z0-9+/_=-]');
final _whitespace = RegExp(r'\s+');
final _padding = RegExp(r'=+$');

String encodeBase64(String text, {bool urlSafe = false}) {
  final bytes = utf8.encode(text);
  if (!urlSafe) return base64.encode(bytes);
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Accepts the standard and URL-safe alphabets, missing padding and line breaks.
Result<String, String> decodeBase64(String input) {
  final clean = input.replaceAll(_whitespace, '');
  if (!_alphabet.hasMatch(clean)) {
    final invalid = _invalidCharacter.firstMatch(clean)?.group(0);
    return Err(
      invalid != null
          ? 'Caractere inválido para Base64: "$invalid".'
          : 'O sinal "=" só pode aparecer no final (padding).',
    );
  }

  final unpadded = clean.replaceAll(_padding, '');
  if (unpadded.length % 4 == 1) {
    return const Err('Tamanho inválido: a entrada parece truncada.');
  }
  final standard = unpadded.replaceAll('-', '+').replaceAll('_', '/');
  final padded = standard.padRight((standard.length + 3) ~/ 4 * 4, '=');

  final List<int> bytes;
  try {
    bytes = base64.decode(padded);
  } on FormatException {
    return const Err('Base64 inválido.');
  }
  try {
    return Ok(utf8.decode(bytes));
  } on FormatException {
    return const Err(
      'O conteúdo decodificado não é texto UTF-8 (provavelmente é um arquivo binário).',
    );
  }
}
