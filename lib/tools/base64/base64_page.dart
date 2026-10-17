import 'package:flutter/material.dart';

import '../../core/base64_text.dart';
import '../../core/result.dart';
import '../../core/text_size.dart';
import '../../widgets/code_field.dart';
import '../../widgets/copy_button.dart';
import '../../widgets/status_message.dart';
import '../../widgets/two_pane_editor.dart';

enum _Direction { encode, decode }

class Base64Page extends StatefulWidget {
  const Base64Page({super.key});

  @override
  State<Base64Page> createState() => _Base64PageState();
}

class _Base64PageState extends State<Base64Page> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  _Direction _direction = _Direction.encode;
  bool _urlSafe = false;
  Result<String, String>? _result;

  bool get _encoding => _direction == _Direction.encode;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _update() {
    final text = _input.text;
    setState(() {
      _result = text.isEmpty
          ? null
          : _encoding
          ? Ok(encodeBase64(text, urlSafe: _urlSafe))
          : decodeBase64(text);
      _output.text = switch (_result) {
        Ok(:final value) => value,
        _ => '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_Direction>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _Direction.encode,
                  label: Text('Codificar'),
                ),
                ButtonSegment(
                  value: _Direction.decode,
                  label: Text('Decodificar'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) {
                _direction = selection.first;
                _update();
              },
            ),
            if (_encoding)
              FilterChip(
                label: const Text('URL-safe (base64url)'),
                selected: _urlSafe,
                onSelected: (value) {
                  _urlSafe = value;
                  _update();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TwoPaneEditor(
            input: CodeField(
              label: _encoding ? 'Texto' : 'Base64',
              controller: _input,
              onChanged: (_) => _update(),
              hintText: _encoding
                  ? 'Olá, mundo! 👋'
                  : 'T2zDoSwgbXVuZG8hIPCfkYs=',
              hasError: _result is Err,
              actions: [
                ClearButton(
                  onPressed: _input.text.isEmpty
                      ? null
                      : () {
                          _input.clear();
                          _update();
                        },
                ),
              ],
            ),
            output: CodeField(
              label: _encoding ? 'Base64' : 'Texto',
              controller: _output,
              readOnly: true,
              hintText: 'O resultado aparece aqui enquanto você digita.',
              actions: [CopyButton(text: _output.text)],
            ),
            status: switch (_result) {
              null => null,
              Ok(:final value) => StatusMessage(
                tone: Tone.success,
                title: _encoding ? 'Codificado' : 'Decodificado',
                message:
                    '${formatBytes(utf8Length(_input.text))} → ${formatBytes(utf8Length(value))}',
              ),
              Err(:final error) => StatusMessage(
                tone: Tone.error,
                title: 'Base64 inválido',
                message: error,
              ),
            },
          ),
        ),
      ],
    );
  }
}
