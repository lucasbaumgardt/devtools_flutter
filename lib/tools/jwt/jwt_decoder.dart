import 'dart:convert';

import '../../core/base64_text.dart';
import '../../core/result.dart';
import '../json/json_formatter.dart';

// Decoding only. The signature is NOT verified: verifying needs the secret or
// public key, and anyone can build a token with arbitrary claims. Everything
// happens on the device; the token is never sent anywhere.

class DecodedPart {
  const DecodedPart(this.claims, this.json);

  final Map<String, Object?> claims;

  /// Pretty-printed from the original text, so numbers are shown exactly.
  final String json;
}

class DecodedJwt {
  const DecodedJwt(this.header, this.payload, this.signature);

  final DecodedPart header;
  final DecodedPart payload;
  final String signature;
}

final _bearer = RegExp(r'^Bearer\s+', caseSensitive: false);
final _whitespace = RegExp(r'\s+');

Result<DecodedJwt, String> decodeJwt(String input) {
  final token = input
      .trim()
      .replaceFirst(_bearer, '')
      .replaceAll(_whitespace, '');
  final parts = token.split('.');

  if (parts.length == 5) {
    return const Err(
      'Este é um JWE (token criptografado, com 5 partes). Sem a chave, o conteúdo não pode ser lido.',
    );
  }
  if (parts.length != 3) {
    return Err(
      'Um JWT tem 3 partes separadas por ponto (header.payload.assinatura), '
      'mas este tem ${parts.length}.',
    );
  }

  final header = _decodePart(parts[0], 'Header');
  final payload = _decodePart(parts[1], 'Payload');
  return switch ((header, payload)) {
    (Err(:final error), _) || (_, Err(:final error)) => Err(error),
    (Ok(value: final h), Ok(value: final p)) => Ok(DecodedJwt(h, p, parts[2])),
  };
}

Result<DecodedPart, String> _decodePart(String segment, String label) {
  if (segment.isEmpty) return Err('$label vazio.');

  final String json;
  switch (decodeBase64(segment)) {
    case Err(:final error):
      return Err('$label: $error');
    case Ok(:final value):
      json = value;
  }

  final Object? value;
  try {
    value = jsonDecode(json);
  } on FormatException {
    return Err('$label não contém JSON válido.');
  }
  if (value is! Map<String, Object?>) {
    return Err('$label deveria ser um objeto JSON.');
  }

  final pretty = switch (formatJson(json)) {
    Ok(:final value) => value,
    Err() => json,
  };
  return Ok(DecodedPart(value, pretty));
}

class TimeClaim {
  const TimeClaim(this.name, this.label, this.seconds);

  final String name;
  final String label;

  /// Seconds since the Unix epoch (NumericDate, RFC 7519).
  final num seconds;
}

const _timeClaims = [
  ('iat', 'Emitido em'),
  ('nbf', 'Válido a partir de'),
  ('exp', 'Expira em'),
];

num? _numericDate(Object? value) =>
    value is num && value.isFinite ? value : null;

List<TimeClaim> timeClaims(Map<String, Object?> payload) => [
  for (final (name, label) in _timeClaims)
    if (_numericDate(payload[name]) case final seconds?)
      TimeClaim(name, label, seconds),
];

enum TokenTiming { expired, notYetValid, active, noExpiry }

/// What the time claims say. Informative only: it says nothing about authenticity.
TokenTiming tokenTiming(Map<String, Object?> payload, {DateTime? now}) {
  final nowSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch / 1000;
  final exp = _numericDate(payload['exp']);
  final nbf = _numericDate(payload['nbf']);
  if (exp != null && exp <= nowSeconds) return TokenTiming.expired;
  if (nbf != null && nbf > nowSeconds) return TokenTiming.notYetValid;
  return exp == null ? TokenTiming.noExpiry : TokenTiming.active;
}
