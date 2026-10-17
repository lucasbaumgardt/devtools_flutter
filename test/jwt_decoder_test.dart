import 'dart:convert';

import 'package:devtools_flutter/core/base64_text.dart';
import 'package:devtools_flutter/core/result.dart';
import 'package:devtools_flutter/tools/jwt/jwt_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a token for tests: header.payload.signature (not really signed).
String makeToken(
  Object payload, {
  Map<String, Object?> header = const {'alg': 'HS256', 'typ': 'JWT'},
  String signature = 'c2lnbmF0dXJl',
}) {
  String encode(Object part) =>
      encodeBase64(part is String ? part : jsonEncode(part), urlSafe: true);
  return [encode(header), encode(payload), signature].join('.');
}

DecodedJwt decoded(String token) => switch (decodeJwt(token)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError(error),
};

String errorOf(String token) => switch (decodeJwt(token)) {
  Err(:final error) => error,
  Ok() => throw StateError('expected an error'),
};

void main() {
  group('decodeJwt', () {
    test('decodes header, payload and signature', () {
      final token = decoded(
        makeToken({'sub': '42', 'name': 'Lucas', 'admin': true}),
      );
      expect(token.header.claims, {'alg': 'HS256', 'typ': 'JWT'});
      expect(token.payload.claims, {
        'sub': '42',
        'name': 'Lucas',
        'admin': true,
      });
      expect(token.signature, 'c2lnbmF0dXJl');
      expect(
        token.payload.json,
        '{\n  "sub": "42",\n  "name": "Lucas",\n  "admin": true\n}',
      );
    });

    test('decodes the well-known jwt.io example token', () {
      const token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
          'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      expect(decoded(token).payload.claims, {
        'sub': '1234567890',
        'name': 'John Doe',
        'iat': 1516239022,
      });
    });

    test('handles Unicode claims and keeps large numbers exact', () {
      expect(
        decoded(makeToken({'name': 'João 👋'})).payload.claims['name'],
        'João 👋',
      );
      expect(
        decoded(makeToken('{"id":12345678901234567890}')).payload.json,
        '{\n  "id": 12345678901234567890\n}',
      );
    });

    test('accepts a "Bearer" prefix and line breaks', () {
      final token = makeToken({'sub': '1'});
      expect(decoded('Bearer $token\n').payload.claims, {'sub': '1'});
      expect(decoded(token.replaceFirst('.', '.\n')).payload.claims, {
        'sub': '1',
      });
    });

    test('accepts unsigned tokens (alg: none, empty signature)', () {
      expect(
        decoded(
          makeToken({'sub': '1'}, header: {'alg': 'none'}, signature: ''),
        ).signature,
        '',
      );
    });

    test('rejects tokens without three parts and explains JWE', () {
      expect(errorOf('abc.def'), contains('mas este tem 2'));
      expect(errorOf('not a token'), contains('3 partes'));
      expect(errorOf('a.b.c.d.e'), contains('JWE'));
    });

    test('reports which part is broken', () {
      expect(errorOf('%%%.e30.sig'), startsWith('Header: Caractere inválido'));
      final header = makeToken({}).split('.').first;
      expect(
        errorOf('$header.bm90IGpzb24.sig'),
        'Payload não contém JSON válido.',
      );
      expect(
        errorOf(makeToken('[1,2]')),
        'Payload deveria ser um objeto JSON.',
      );
    });
  });

  group('time claims', () {
    final now = DateTime.utc(2024, 10, 17, 12);
    final seconds = now.millisecondsSinceEpoch ~/ 1000;

    test('lists iat, nbf and exp in that order when they are numbers', () {
      expect(timeClaims({'exp': 2, 'iat': 1, 'sub': 'x'}).map((c) => c.name), [
        'iat',
        'exp',
      ]);
      expect(timeClaims({'exp': 'soon'}), isEmpty);
    });

    test('tells expired, not yet valid, active and no-expiry tokens apart', () {
      expect(tokenTiming({'exp': seconds - 1}, now: now), TokenTiming.expired);
      expect(
        tokenTiming({'nbf': seconds + 60, 'exp': seconds + 3600}, now: now),
        TokenTiming.notYetValid,
      );
      expect(
        tokenTiming({'exp': seconds + 3600}, now: now),
        TokenTiming.active,
      );
      expect(tokenTiming({'sub': 'x'}, now: now), TokenTiming.noExpiry);
    });
  });
}
