import 'dart:convert';

import 'package:devtools_flutter/core/result.dart';
import 'package:devtools_flutter/tools/json/json_formatter.dart';
import 'package:devtools_flutter/tools/json/json_syntax.dart';
import 'package:flutter_test/flutter_test.dart';

String formatted(Result<String, JsonError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('expected success: ${error.message}'),
};

JsonError errorOf(String input) => switch (formatJson(input)) {
  Err(:final error) => error,
  Ok() => throw StateError('expected an error'),
};

void main() {
  group('formatJson', () {
    test('formats the example from the spec', () {
      expect(
        formatted(formatJson('{\n"name":"Lucas",\n"age":30\n}')),
        '{\n  "name": "Lucas",\n  "age": 30\n}',
      );
    });

    test('supports 4 spaces and tab indentation', () {
      expect(
        formatted(formatJson('{"a":[1]}', JsonIndent.four)),
        '{\n    "a": [\n        1\n    ]\n}',
      );
      expect(
        formatted(formatJson('{"a":1}', JsonIndent.tab)),
        '{\n\t"a": 1\n}',
      );
    });

    test('keeps empty containers on one line', () {
      expect(
        formatted(formatJson('{"a":{},"b":[ ],"c":[{"d":null}]}')),
        '{\n  "a": {},\n  "b": [],\n  "c": [\n    {\n      "d": null\n    }\n  ]\n}',
      );
    });

    test('accepts top-level scalars', () {
      expect(formatted(formatJson(' "text" ')), '"text"');
      expect(formatted(formatJson('42')), '42');
    });

    test(
      'preserves big integers, number spelling, escapes and duplicate keys',
      () {
        const input =
            r'{"id":12345678901234567890,"price":1.0,"text":"café \"x\"","a":1,"a":2}';
        expect(
          formatted(formatJson(input)),
          '{\n'
          '  "id": 12345678901234567890,\n'
          '  "price": 1.0,\n'
          r'  "text": "café \"x\"",'
          '\n'
          '  "a": 1,\n'
          '  "a": 2\n'
          '}',
        );
      },
    );

    test('does not touch structural characters inside strings', () {
      expect(
        formatted(formatJson('{"s":"a, b: {c} [d]"}')),
        '{\n  "s": "a, b: {c} [d]"\n}',
      );
    });
  });

  group('minifyJson', () {
    test('removes whitespace outside strings only', () {
      expect(
        formatted(
          minifyJson(
            '{\n  "name": "Lucas Freitas",\n  "tags": [ "a", "b" ]\n}',
          ),
        ),
        '{"name":"Lucas Freitas","tags":["a","b"]}',
      );
    });

    test('round-trips with formatJson', () {
      const compact = '{"a":[1,2,{"b":"c"}],"d":{"e":true,"f":[]}}';
      expect(formatted(minifyJson(formatted(formatJson(compact)))), compact);
    });
  });

  group('invalid JSON', () {
    final cases = <(String, String, int)>[
      ('{"a":1,}', 'Vírgula sobrando antes de "}".', 7),
      ('[1,2,]', 'Vírgula sobrando antes de "]".', 5),
      ("{'a':1}", 'Nome de propriedade com aspas simples.', 2),
      ('{a:1}', 'Nome de propriedade sem aspas.', 2),
      ('{"a":1 "b":2}', 'Era esperado "," ou "}" depois do valor.', 8),
      ('{"a" 1}', 'Era esperado ":" depois do nome da propriedade.', 6),
      ('{"a":}', 'Era esperado um valor.', 6),
      ("{\"a\":'x'}", 'Valor inválido.', 6),
      ('{"a":undefined}', '"undefined" não é um valor JSON.', 6),
      ('{"a":True}', '"True" não é um valor JSON.', 6),
      ('[1, 2', 'O JSON terminou antes do esperado.', 6),
      ('{"a":"abc}', 'String sem aspas de fechamento.', 6),
      ('{"a":1} {"b":2}', 'Há conteúdo depois do fim do JSON.', 9),
      ('// comment\n{}', 'Comentários não são permitidos em JSON.', 1),
      ('{"a":01}', 'Número inválido.', 6),
      ('{"a":-}', 'Número inválido.', 6),
      (r'{"a":"\x"}', 'Sequência de escape inválida.', 7),
      (
        '{"a":"line\nbreak"}',
        'Caractere de controle dentro de uma string.',
        11,
      ),
      (
        '${String.fromCharCode(0xFEFF)}{}',
        'Caractere inesperado: marca BOM invisível (U+FEFF).',
        1,
      ),
    ];

    for (final (input, message, column) in cases) {
      test('${jsonEncode(input)} → $message', () {
        final error = errorOf(input);
        expect(error.message, message);
        expect(error.line, 1);
        expect(error.column, column);
      });
    }

    test('reports line, column, hint and excerpt on multi-line input', () {
      final error = errorOf('{\n  "a": 1,\n  "b": 2,\n}');
      expect(error.line, 3);
      expect(error.column, 9);
      expect(error.hint, 'JSON não aceita vírgula depois do último item.');
      expect(error.excerpt, '  "b": 2,');
      expect(error.caret, 8);
    });

    test('shows a window of very long (minified) lines', () {
      final error = errorOf('[${'1,' * 100}x]');
      expect(error.column, 202);
      expect(error.excerpt, startsWith('…'));
      expect(error.excerpt![error.caret!], 'x');
    });
  });

  group('findJsonSyntaxError agrees with jsonDecode', () {
    const samples = [
      '{}',
      '[]',
      r'{"a":[1,2.5e-3,-0,true,false,null,"A\n"]}',
      ' \n\t{"nested":{"deep":[[[]]]}} ',
      r'"\/"',
      '{"a":1,}',
      '[,1]',
      '{"a" "b"}',
      '01',
      '1.',
      '.5',
      '+1',
      '1e',
      '"\t"',
      'nul',
      '[1 2]',
      '{"a":1}}',
      '',
    ];

    for (final sample in samples) {
      test(jsonEncode(sample), () {
        var parses = true;
        try {
          jsonDecode(sample);
        } on FormatException {
          parses = false;
        }
        expect(findJsonSyntaxError(sample) == null, parses);
      });
    }
  });
}
