import 'dart:convert';

int utf8Length(String text) => utf8.encode(text).length;

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${_decimal(bytes / 1024)} KB';
  return '${_decimal(bytes / (1024 * 1024))} MB';
}

String _decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
