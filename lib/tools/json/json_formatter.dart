import 'dart:convert';

import '../../core/result.dart';
import 'json_syntax.dart';

enum JsonIndent {
  two('2 espaços', '  '),
  four('4 espaços', '    '),
  tab('Tab', '\t');

  const JsonIndent(this.label, this.characters);

  final String label;
  final String characters;
}

class JsonError {
  const JsonError({
    required this.message,
    this.hint,
    this.line,
    this.column,
    this.excerpt,
    this.caret,
  });

  final String message;
  final String? hint;
  final int? line;
  final int? column;

  /// The offending line (trimmed when long) and the caret offset within it.
  final String? excerpt;
  final int? caret;
}

Result<String, JsonError> formatJson(
  String input, [
  JsonIndent indent = JsonIndent.two,
]) {
  final error = validateJson(input);
  return error == null ? Ok(_reformat(input, indent.characters)) : Err(error);
}

Result<String, JsonError> minifyJson(String input) {
  final error = validateJson(input);
  return error == null ? Ok(_reformat(input, null)) : Err(error);
}

/// Returns null when [input] is valid JSON.
JsonError? validateJson(String input) {
  try {
    jsonDecode(input);
    return null;
  } on FormatException catch (exception) {
    final issue = findJsonSyntaxError(input);
    if (issue == null) return JsonError(message: exception.message);
    return _locate(input, issue);
  }
}

const _whitespace = ' \t\n\r';
const _closing = {'{': '}', '[': ']'};

/// Re-indents already validated JSON token by token instead of
/// jsonEncode(jsonDecode(...)). Decoding would silently change the data:
/// big integers lose precision, `1.0` becomes `1`, escapes are rewritten and
/// duplicate keys disappear.
String _reformat(String text, String? indent) {
  final out = StringBuffer();
  var depth = 0;
  void newline() {
    if (indent != null) out.write('\n${indent * depth}');
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (_whitespace.contains(char)) continue;

    final close = _closing[char];
    if (close != null) {
      final next = _skipWhitespace(text, i + 1);
      if (next < text.length && text[next] == close) {
        out.write('$char$close'); // keep empty containers on one line
        i = next;
      } else {
        depth++;
        out.write(char);
        newline();
      }
    } else if (char == '}' || char == ']') {
      depth--;
      newline();
      out.write(char);
    } else if (char == ',') {
      out.write(',');
      newline();
    } else if (char == ':') {
      out.write(indent == null ? ':' : ': ');
    } else {
      // string, number or literal: copied verbatim
      final end = char == '"' ? _stringEnd(text, i) : _literalEnd(text, i);
      out.write(text.substring(i, end + 1));
      i = end;
    }
  }
  return out.toString();
}

int _stringEnd(String text, int start) {
  var i = start + 1;
  while (text[i] != '"') {
    i += text[i] == '\\' ? 2 : 1;
  }
  return i;
}

int _literalEnd(String text, int start) {
  var end = start;
  while (end + 1 < text.length && !',:]} \t\n\r'.contains(text[end + 1])) {
    end++;
  }
  return end;
}

int _skipWhitespace(String text, int from) {
  var i = from;
  while (i < text.length && _whitespace.contains(text[i])) {
    i++;
  }
  return i;
}

const _excerptWidth = 60;

JsonError _locate(String text, JsonSyntaxIssue issue) {
  var line = 1;
  var lineStart = 0;
  for (var i = 0; i < issue.position && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  final column = issue.position - lineStart + 1;
  final lineEnd = text.indexOf('\n', lineStart);
  final lineText = text
      .substring(lineStart, lineEnd == -1 ? text.length : lineEnd)
      .replaceAll('\r', '');

  // Long (e.g. minified) lines: show a window around the error.
  final from = (column - 1 - _excerptWidth ~/ 2).clamp(0, lineText.length);
  final to = (from + _excerptWidth).clamp(0, lineText.length);
  final prefix = from > 0 ? '…' : '';
  final suffix = to < lineText.length ? '…' : '';

  return JsonError(
    message: issue.message,
    hint: issue.hint,
    line: line,
    column: column,
    excerpt:
        '$prefix${lineText.substring(from, to).replaceAll('\t', ' ')}$suffix',
    caret: column - 1 - from + prefix.length,
  );
}
