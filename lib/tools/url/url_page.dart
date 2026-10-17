import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../widgets/code_field.dart';
import '../../widgets/copy_button.dart';
import '../../widgets/status_message.dart';
import '../../widgets/two_pane_editor.dart';
import 'url_codec.dart';

enum _Direction { encode, decode }

class UrlPage extends StatefulWidget {
  const UrlPage({super.key});

  @override
  State<UrlPage> createState() => _UrlPageState();
}

class _UrlPageState extends State<UrlPage> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  _Direction _direction = _Direction.encode;
  bool _fullUrl = false;
  bool _plusAsSpace = false;
  Result<String, String>? _result;

  bool get _encoding => _direction == _Direction.encode;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  Result<String, String>? _convert(String text) {
    if (text.isEmpty) return null;
    return _encoding
        ? encodeUrl(text, fullUrl: _fullUrl)
        : decodeUrl(text, plusAsSpace: _plusAsSpace);
  }

  void _update() {
    setState(() {
      _result = _convert(_input.text);
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
                ButtonSegment(value: _Direction.encode, label: Text('Encode')),
                ButtonSegment(value: _Direction.decode, label: Text('Decode')),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) {
                _direction = selection.first;
                _update();
              },
            ),
            if (_encoding)
              FilterChip(
                label: const Text('URL completa (preserva : / ? # & =)'),
                selected: _fullUrl,
                onSelected: (value) {
                  _fullUrl = value;
                  _update();
                },
              )
            else
              FilterChip(
                label: const Text('Tratar + como espaço (formulários)'),
                selected: _plusAsSpace,
                onSelected: (value) {
                  _plusAsSpace = value;
                  _update();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TwoPaneEditor(
            input: CodeField(
              label: _encoding ? 'Texto' : 'Texto codificado',
              controller: _input,
              onChanged: (_) => _update(),
              hintText: _encoding
                  ? 'nome=João & cidade=São Paulo'
                  : 'nome%3DJo%C3%A3o%20%26%20cidade%3DS%C3%A3o',
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
              label: 'Resultado',
              controller: _output,
              readOnly: true,
              hintText: 'O resultado aparece aqui enquanto você digita.',
              actions: [CopyButton(text: _output.text)],
            ),
            status: switch (_result) {
              Err(:final error) => StatusMessage(
                tone: Tone.error,
                title: 'Não foi possível converter',
                message: error,
              ),
              _ => null,
            },
          ),
        ),
      ],
    );
  }
}
