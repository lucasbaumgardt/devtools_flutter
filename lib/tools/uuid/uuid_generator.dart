import 'dart:math';

import '../../core/result.dart';

const maxUuids = 1000;

final _random = Random.secure();

/// Builds an RFC 9562 version 4 UUID from 16 random bytes.
String uuidV4FromBytes(List<int> bytes) {
  final b = List<int>.of(bytes);
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
  final hex = b.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

String generateUuid() =>
    uuidV4FromBytes(List<int>.generate(16, (_) => _random.nextInt(256)));

List<String> generateUuids(int count) =>
    List<String>.generate(count, (_) => generateUuid());

Result<int, String> parseCount(String input) {
  final value = int.tryParse(input.trim());
  if (value == null || value < 1 || value > maxUuids) {
    return const Err('Informe um número inteiro entre 1 e $maxUuids.');
  }
  return Ok(value);
}
