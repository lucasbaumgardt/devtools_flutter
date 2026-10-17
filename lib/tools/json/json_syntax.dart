// Locates and explains a JSON syntax error. Only used after jsonDecode has
// failed: the error messages of the Dart VM and of the browsers (on web) differ
// and do not always include a position, so this small scanner gives the same
// message, position and hint everywhere.

class JsonSyntaxIssue {
  const JsonSyntaxIssue(this.message, this.position, [this.hint]);

  final String message;

  /// Offset (UTF-16 code units) where the problem was detected.
  final int position;
  final String? hint;
}

class _ScanError implements Exception {
  const _ScanError(this.issue);

  final JsonSyntaxIssue issue;
}

final _number = RegExp(r'-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?');
final _word = RegExp(r'[A-Za-z_$][\w$]*');
final _hex4 = RegExp(r'^[0-9a-fA-F]{4}$');
final _valueStart = RegExp(r'^["{\[\-0-9tfn]$');
const _simpleEscapes = {'"', '\\', '/', 'b', 'f', 'n', 'r', 't'};
const _trailingCommaHint = 'JSON não aceita vírgula depois do último item.';

JsonSyntaxIssue? findJsonSyntaxError(String text) {
  try {
    _Scanner(text).document();
    return null;
  } on _ScanError catch (error) {
    return error.issue;
  } on StackOverflowError {
    // Absurdly deep nesting: the caller falls back to the parser message.
    return null;
  }
}

Never _fail(String message, int at, [String? hint]) =>
    throw _ScanError(JsonSyntaxIssue(message, at, hint));

bool _isWhitespace(String char) =>
    char == ' ' || char == '\t' || char == '\n' || char == '\r';

bool _isDigit(String char) =>
    char.isNotEmpty && char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39;

String _describe(String char) {
  final code = char.codeUnitAt(0);
  final hex = 'U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  if (code == 0xFEFF) return 'marca BOM invisível ($hex)';
  if (code == 0x00A0) return 'espaço não separável ($hex)';
  if (code < 0x20 || (code >= 0x7f && code <= 0x9f)) {
    return 'caractere de controle ($hex)';
  }
  return '"$char"';
}

/// Walks the JSON grammar and throws a [_ScanError] at the first problem.
class _Scanner {
  _Scanner(this.text);

  final String text;
  int pos = 0;

  String get char => _charAt(pos);

  String _charAt(int index) => index < text.length ? text[index] : '';

  void document() {
    value();
    skipWhitespace();
    if (pos < text.length) {
      _fail(
        'Há conteúdo depois do fim do JSON.',
        pos,
        'Só pode existir um valor raiz. Há dois JSONs colados ou um caractere sobrando?',
      );
    }
  }

  Never endOfInput() => _fail(
    'O JSON terminou antes do esperado.',
    text.trimRight().length,
    'Verifique se todas as chaves { } e colchetes [ ] foram fechados.',
  );

  void skipWhitespace() {
    while (pos < text.length && _isWhitespace(char)) {
      pos++;
    }
  }

  String? readWord() => _word.matchAsPrefix(text, pos)?.group(0);

  void value() {
    skipWhitespace();
    final c = char;
    if (c.isEmpty) {
      endOfInput();
    } else if (c == '{') {
      object();
    } else if (c == '[') {
      array();
    } else if (c == '"') {
      string();
    } else if (c == '-' || _isDigit(c)) {
      number();
    } else if (!literal()) {
      invalidValue(c);
    }
  }

  bool literal() {
    for (final word in const ['true', 'false', 'null']) {
      if (text.startsWith(word, pos)) {
        pos += word.length;
        return true;
      }
    }
    return false;
  }

  Never invalidValue(String c) {
    final at = pos;
    if (c == "'") {
      _fail(
        'Valor inválido.',
        at,
        'Strings em JSON usam aspas duplas ("texto"), não aspas simples.',
      );
    }
    if (c == '/') {
      _fail(
        'Comentários não são permitidos em JSON.',
        at,
        'Remova os // ou /* */.',
      );
    }
    if (c == '+') {
      _fail(
        'Número inválido.',
        at,
        'Números em JSON não podem começar com "+".',
      );
    }
    if (c == '.') {
      _fail(
        'Número inválido.',
        at,
        'Escreva o zero antes do ponto: 0.5 em vez de .5.',
      );
    }
    if (c == ',' || c == '}' || c == ']') {
      _fail(
        'Era esperado um valor.',
        at,
        'Há uma vírgula sobrando ou um valor faltando.',
      );
    }
    final word = readWord();
    if (word == 'undefined' || word == 'NaN' || word == 'Infinity') {
      _fail('"$word" não é um valor JSON.', at, 'Use null ou um número.');
    }
    if (word != null &&
        RegExp(
          r'^(true|false|null|none)$',
          caseSensitive: false,
        ).hasMatch(word)) {
      _fail(
        '"$word" não é um valor JSON.',
        at,
        'Use true, false ou null, em minúsculas.',
      );
    }
    if (word != null) {
      _fail(
        'Valor inválido.',
        at,
        'Textos precisam estar entre aspas duplas: "texto".',
      );
    }
    _fail('Caractere inesperado: ${_describe(c)}.', at);
  }

  void object() {
    pos++; // {
    skipWhitespace();
    if (char == '}') {
      pos++;
      return;
    }
    do {
      skipWhitespace();
      propertyName();
      skipWhitespace();
      if (char != ':') {
        if (pos >= text.length) endOfInput();
        _fail('Era esperado ":" depois do nome da propriedade.', pos);
      }
      pos++;
      value();
    } while (!endOfList('}'));
  }

  void propertyName() {
    final c = char;
    if (c == '"') {
      string();
      return;
    }
    if (c.isEmpty) endOfInput();
    if (c == "'") {
      _fail(
        'Nome de propriedade com aspas simples.',
        pos,
        'Use aspas duplas: "nome".',
      );
    }
    if (readWord() != null) {
      _fail(
        'Nome de propriedade sem aspas.',
        pos,
        'Coloque o nome entre aspas duplas: "nome".',
      );
    }
    _fail('Era esperado o nome de uma propriedade entre aspas duplas.', pos);
  }

  void array() {
    pos++; // [
    skipWhitespace();
    if (char == ']') {
      pos++;
      return;
    }
    do {
      value();
    } while (!endOfList(']'));
  }

  /// After an object member or array item: consumes "," (returns false, more
  /// items follow) or the closing bracket (returns true). Anything else fails.
  bool endOfList(String close) {
    skipWhitespace();
    final c = char;
    if (c == close) {
      pos++;
      return true;
    }
    if (c == ',') {
      final comma = pos++;
      skipWhitespace();
      if (char == close) {
        _fail('Vírgula sobrando antes de "$close".', comma, _trailingCommaHint);
      }
      return false;
    }
    if (c.isEmpty) endOfInput();
    if (close == '}') {
      _fail(
        'Era esperado "," ou "}" depois do valor.',
        pos,
        c == '"' ? 'Parece faltar uma vírgula entre as propriedades.' : null,
      );
    }
    _fail(
      'Era esperado "," ou "]" depois do item.',
      pos,
      _valueStart.hasMatch(c)
          ? 'Parece faltar uma vírgula entre os itens.'
          : null,
    );
  }

  void string() {
    final start = pos;
    pos++; // opening quote
    while (true) {
      final c = char;
      if (c.isEmpty) {
        _fail(
          'String sem aspas de fechamento.',
          start,
          'Feche a string com aspas duplas (").',
        );
      }
      if (c == '"') {
        pos++;
        return;
      }
      if (c == '\\') {
        escape();
      } else if (c.codeUnitAt(0) < 0x20) {
        controlCharacter(c);
      } else {
        pos++;
      }
    }
  }

  void escape() {
    final next = _charAt(pos + 1);
    if (_simpleEscapes.contains(next)) {
      pos += 2;
      return;
    }
    final digits = text.substring(
      (pos + 2).clamp(0, text.length),
      (pos + 6).clamp(0, text.length),
    );
    if (next == 'u' && _hex4.hasMatch(digits)) {
      pos += 6;
      return;
    }
    _fail(
      'Sequência de escape inválida.',
      pos,
      'Escapes válidos: \\" \\\\ \\/ \\b \\f \\n \\r \\t e \\uXXXX.',
    );
  }

  Never controlCharacter(String c) {
    final hint = switch (c) {
      '\n' =>
        'Faltou fechar a string? Quebras de linha dentro de strings são escritas como \\n.',
      '\t' => 'Tabulações dentro de strings são escritas como \\t.',
      _ => 'Caracteres de controle precisam ser escapados como \\uXXXX.',
    };
    _fail('Caractere de controle dentro de uma string.', pos, hint);
  }

  void number() {
    final start = pos;
    final match = _number.matchAsPrefix(text, start);
    if (match == null) {
      _fail(
        'Número inválido.',
        start,
        text.startsWith('-Infinity', start)
            ? 'Use null ou um número.'
            : 'Falta o número depois do sinal de menos.',
      );
    }
    pos = match.end;
    final next = char;
    if (_isDigit(next)) {
      _fail(
        'Número inválido.',
        start,
        'Números não podem ter zeros à esquerda.',
      );
    }
    if (next == '.') {
      _fail(
        'Número inválido.',
        start,
        'Coloque dígitos depois do ponto decimal.',
      );
    }
    if (next == 'e' || next == 'E') {
      _fail('Número inválido.', start, 'O expoente está incompleto.');
    }
  }
}
