import 'package:devtools_flutter/core/base64_text.dart';
import 'package:devtools_flutter/core/result.dart';
import 'package:devtools_flutter/tools/url/url_codec.dart';
import 'package:devtools_flutter/tools/uuid/uuid_generator.dart';
import 'package:flutter_test/flutter_test.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

String? valueOf(Result<String, String> result) =>
    result is Ok<String, String> ? result.value : null;

String? errorOf(Result<String, String> result) =>
    result is Err<String, String> ? result.error : null;

void main() {
  group('Base64', () {
    test('encodes ASCII and Unicode text as UTF-8', () {
      expect(encodeBase64('hello'), 'aGVsbG8=');
      expect(encodeBase64('Olá, mundo! 👋'), 'T2zDoSwgbXVuZG8hIPCfkYs=');
      expect(encodeBase64('ação'), 'YcOnw6Nv');
    });

    test('produces base64url without padding when asked', () {
      expect(encodeBase64('???'), 'Pz8/');
      expect(encodeBase64('???', urlSafe: true), 'Pz8_');
      expect(encodeBase64('>>>', urlSafe: true), 'Pj4-');
      expect(encodeBase64('a', urlSafe: true), 'YQ');
    });

    test('decodes back to Unicode text', () {
      expect(
        valueOf(decodeBase64('T2zDoSwgbXVuZG8hIPCfkYs=')),
        'Olá, mundo! 👋',
      );
    });

    test('accepts base64url, missing padding and line breaks', () {
      expect(valueOf(decodeBase64('Pz8_')), '???');
      expect(valueOf(decodeBase64('YQ')), 'a');
      expect(valueOf(decodeBase64('aGVs\nbG8=\n')), 'hello');
    });

    test('round-trips large inputs', () {
      final text = 'ação 👋 ' * 20000;
      expect(valueOf(decodeBase64(encodeBase64(text))), text);
    });

    test('explains invalid input', () {
      expect(
        errorOf(decodeBase64(r'abc$')),
        'Caractere inválido para Base64: "\$".',
      );
      expect(errorOf(decodeBase64('YQ==YQ==')), isNotNull);
      expect(
        errorOf(decodeBase64('abcde')),
        'Tamanho inválido: a entrada parece truncada.',
      );
      expect(errorOf(decodeBase64('//4=')), contains('não é texto UTF-8'));
    });
  });

  group('URL', () {
    test('encodes a value for use inside a URL', () {
      expect(
        valueOf(encodeUrl('nome=João & cidade=São Paulo')),
        'nome%3DJo%C3%A3o%20%26%20cidade%3DS%C3%A3o%20Paulo',
      );
    });

    test('keeps the structure of a full URL', () {
      expect(
        valueOf(
          encodeUrl(
            'https://exemplo.com/busca?q=café com leite&ordem=asc#topo',
            fullUrl: true,
          ),
        ),
        'https://exemplo.com/busca?q=caf%C3%A9%20com%20leite&ordem=asc#topo',
      );
    });

    test('decodes percent-encoded UTF-8 and round-trips emoji', () {
      expect(
        valueOf(
          decodeUrl('nome%3DJo%C3%A3o%20%26%20cidade%3DS%C3%A3o%20Paulo'),
        ),
        'nome=João & cidade=São Paulo',
      );
      expect(valueOf(decodeUrl(valueOf(encodeUrl('👋 olá'))!)), '👋 olá');
    });

    test('keeps "+" unless form decoding is enabled', () {
      expect(valueOf(decodeUrl('a+b%2Bc')), 'a+b+c');
      expect(valueOf(decodeUrl('a+b%2Bc', plusAsSpace: true)), 'a b+c');
    });

    test('points to a malformed "%"', () {
      expect(errorOf(decodeUrl('desconto de 100%')), contains('posição 16'));
    });

    test('points to bytes that are not valid UTF-8', () {
      expect(
        errorOf(decodeUrl('ok%20%C3')),
        'Sequência "%20%C3" na posição 3 não forma um caractere UTF-8 válido.',
      );
    });
  });

  group('UUID', () {
    test('sets the version (4) and variant (10xx) bits', () {
      expect(
        uuidV4FromBytes(List.filled(16, 0)),
        '00000000-0000-4000-8000-000000000000',
      );
      expect(
        uuidV4FromBytes(List.filled(16, 0xff)),
        'ffffffff-ffff-4fff-bfff-ffffffffffff',
      );
    });

    test('generates the requested amount of unique v4 UUIDs', () {
      final uuids = generateUuids(1000);
      expect(uuids, hasLength(1000));
      expect(uuids.toSet(), hasLength(1000));
      expect(uuids.every(_uuidV4.hasMatch), isTrue);
    });

    test('validates the amount', () {
      for (final valid in ['1', '25', '1000']) {
        expect(parseCount(valid), isA<Ok<int, String>>());
      }
      for (final invalid in ['', '0', '-3', '2.5', '1001', 'abc']) {
        expect(parseCount(invalid), isA<Err<int, String>>(), reason: invalid);
      }
    });
  });
}
