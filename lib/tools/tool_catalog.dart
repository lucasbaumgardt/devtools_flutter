import 'package:flutter/material.dart';

import 'base64/base64_page.dart';
import 'json/json_page.dart';
import 'jwt/jwt_page.dart';
import 'timestamp/timestamp_page.dart';
import 'url/url_page.dart';
import 'uuid/uuid_page.dart';

class DevTool {
  const DevTool({
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.keywords,
    required this.page,
  });

  /// Page title.
  final String name;

  /// Menu label.
  final String shortName;
  final String description;
  final IconData icon;

  /// Extra search terms (Portuguese and English).
  final List<String> keywords;
  final Widget page;
}

// Adding a tool = one folder in lib/tools/ + one entry here.
const devTools = [
  DevTool(
    name: 'JSON Formatter',
    shortName: 'JSON',
    description:
        'Formate, minifique e valide JSON. Erros mostram linha, coluna e uma dica.',
    icon: Icons.data_object,
    keywords: ['formatar', 'minificar', 'validar', 'prettify', 'beautify'],
    page: JsonPage(),
  ),
  DevTool(
    name: 'UUID Generator',
    shortName: 'UUID',
    description: 'Gere UUIDs v4 aleatórios, um ou vários de uma vez.',
    icon: Icons.tag,
    keywords: ['guid', 'gerar', 'id', 'identificador', 'v4', 'random'],
    page: UuidPage(),
  ),
  DevTool(
    name: 'Base64 Encoder/Decoder',
    shortName: 'Base64',
    description:
        'Converta texto em Base64 e de volta, com suporte completo a Unicode e base64url.',
    icon: Icons.swap_horiz,
    keywords: [
      'codificar',
      'decodificar',
      'encode',
      'decode',
      'b64',
      'base64url',
    ],
    page: Base64Page(),
  ),
  DevTool(
    name: 'URL Encoder/Decoder',
    shortName: 'URL',
    description: 'Codifique e decodifique texto para URLs (percent-encoding).',
    icon: Icons.link,
    keywords: [
      'codificar',
      'decodificar',
      'encode',
      'decode',
      'percent',
      'query',
    ],
    page: UrlPage(),
  ),
  DevTool(
    name: 'Timestamp Converter',
    shortName: 'Timestamp',
    description:
        'Converta Unix timestamps (segundos ou milissegundos) em datas legíveis e vice-versa.',
    icon: Icons.schedule,
    keywords: ['epoch', 'unix', 'data', 'hora', 'date', 'time', 'utc', 'iso'],
    page: TimestampPage(),
  ),
  DevTool(
    name: 'JWT Decoder',
    shortName: 'JWT',
    description:
        'Veja o header e o payload de um JSON Web Token. Apenas decodifica, sem validar a assinatura.',
    icon: Icons.key_outlined,
    keywords: ['token', 'json web token', 'bearer', 'claims', 'decode', 'auth'],
    page: JwtPage(),
  ),
];

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
};

String _normalize(String text) =>
    text.toLowerCase().split('').map((char) => _accents[char] ?? char).join();

/// Accent- and case-insensitive search; every word of the query must match.
List<DevTool> searchTools(String query, [List<DevTool> tools = devTools]) {
  final terms = _normalize(
    query,
  ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  if (terms.isEmpty) return tools;
  return [
    for (final tool in tools)
      if (terms.every(
        _normalize(
          [
            tool.name,
            tool.shortName,
            tool.description,
            ...tool.keywords,
          ].join(' '),
        ).contains,
      ))
        tool,
  ];
}
