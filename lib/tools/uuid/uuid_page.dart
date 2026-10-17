import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/result.dart';
import '../../theme.dart';
import '../../widgets/copy_button.dart';
import 'uuid_generator.dart';

class UuidPage extends StatefulWidget {
  const UuidPage({super.key});

  @override
  State<UuidPage> createState() => _UuidPageState();
}

class _UuidPageState extends State<UuidPage> {
  final _count = TextEditingController(text: '1');

  // One UUID is ready on arrival: open the page, copy, done.
  List<String> _uuids = [generateUuid()];

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  void _generate() {
    if (parseCount(_count.text) case Ok(:final value)) {
      setState(() => _uuids = generateUuids(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = parseCount(_count.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: TextField(
                controller: _count,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantidade',
                  errorText: switch (count) {
                    Err(:final error) => error,
                    Ok() => null,
                  },
                  errorMaxLines: 2,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _generate(),
              ),
            ),
            FilledButton.icon(
              onPressed: count is Ok ? _generate : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Gerar'),
            ),
            CopyButton(text: _uuids.join('\n'), label: 'Copiar todos'),
            ClearButton(
              onPressed: _uuids.isEmpty
                  ? null
                  : () => setState(() => _uuids = []),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _uuids.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum UUID na lista. Escolha a quantidade e toque em Gerar.',
                    textAlign: TextAlign.center,
                  ),
                )
              : Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: _uuids.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => ListTile(
                      dense: true,
                      leading: Text(
                        '${index + 1}',
                        style: codeStyle(context, fontSize: 12).copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: SelectableText(
                        _uuids[index],
                        style: codeStyle(context, fontSize: 14),
                      ),
                      trailing: CopyButton(
                        text: _uuids[index],
                        label: 'Copiar UUID ${index + 1}',
                        iconOnly: true,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
