import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../core/text_size.dart';
import '../../theme.dart';
import '../../widgets/code_field.dart';
import '../../widgets/copy_button.dart';
import '../../widgets/status_message.dart';
import '../../widgets/two_pane_editor.dart';
import 'json_formatter.dart';

enum _Mode { format, minify }

class JsonPage extends StatefulWidget {
  const JsonPage({super.key});

  @override
  State<JsonPage> createState() => _JsonPageState();
}

class _JsonPageState extends State<JsonPage> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  _Mode _mode = _Mode.format;
  JsonIndent _indent = JsonIndent.two;
  Result<String, JsonError>? _result;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  /// Runs on every change: the result updates while you type.
  Result<String, JsonError>? _convert(String text) {
    if (text.trim().isEmpty) return null;
    return _mode == _Mode.format ? formatJson(text, _indent) : minifyJson(text);
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
            SegmentedButton<_Mode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Mode.format, label: Text('Formatar')),
                ButtonSegment(value: _Mode.minify, label: Text('Minificar')),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                _mode = selection.first;
                _update();
              },
            ),
            DropdownMenu<JsonIndent>(
              enabled: _mode == _Mode.format,
              initialSelection: _indent,
              label: const Text('Indentação'),
              dropdownMenuEntries: [
                for (final indent in JsonIndent.values)
                  DropdownMenuEntry(value: indent, label: indent.label),
              ],
              onSelected: (indent) {
                if (indent == null) return;
                _indent = indent;
                _update();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TwoPaneEditor(
            input: CodeField(
              label: 'Entrada',
              controller: _input,
              onChanged: (_) => _update(),
              hintText: '{"name":"Lucas","age":30}',
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
              null => null,
              Ok(:final value) => StatusMessage(
                tone: Tone.success,
                title: 'JSON válido',
                message:
                    '${formatBytes(utf8Length(_input.text))} → ${formatBytes(utf8Length(value))}',
              ),
              Err(:final error) => _JsonErrorMessage(error: error),
            },
          ),
        ),
      ],
    );
  }
}

class _JsonErrorMessage extends StatelessWidget {
  const _JsonErrorMessage({required this.error});

  final JsonError error;

  @override
  Widget build(BuildContext context) {
    final where = error.line == null
        ? ''
        : ' — linha ${error.line}, coluna ${error.column}';
    final excerpt = error.excerpt;
    return StatusMessage(
      tone: Tone.error,
      title: 'JSON inválido$where',
      message: error.message,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error.hint != null)
            Text(
              error.hint!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (excerpt != null)
            ExcludeSemantics(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    '$excerpt\n${' ' * (error.caret ?? 0)}^',
                    style: codeStyle(context, fontSize: 12),
                    softWrap: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
