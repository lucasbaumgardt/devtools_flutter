import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../widgets/result_row.dart';
import '../../widgets/status_message.dart';
import 'timestamp_converter.dart';

int _nowInSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

class TimestampPage extends StatelessWidget {
  const TimestampPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _TimestampToDate(),
        SizedBox(height: 16),
        _DateToTimestamp(),
        SizedBox(height: 16),
      ],
    );
  }
}

class _TimestampToDate extends StatefulWidget {
  const _TimestampToDate();

  @override
  State<_TimestampToDate> createState() => _TimestampToDateState();
}

class _TimestampToDateState extends State<_TimestampToDate> {
  final _input = TextEditingController(text: '${_nowInSeconds()}');
  UnitChoice _unit = UnitChoice.auto;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _now() {
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _input.text = '${_unit == UnitChoice.milliseconds ? now : now ~/ 1000}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _input.text.trim().isEmpty
        ? null
        : parseTimestamp(_input.text, _unit);
    return _Card(
      title: 'Timestamp → data',
      controls: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _input,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Timestamp Unix',
              hintText: '1729171200',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SegmentedButton<UnitChoice>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: UnitChoice.auto, label: Text('Auto')),
            ButtonSegment(value: UnitChoice.seconds, label: Text('Segundos')),
            ButtonSegment(
              value: UnitChoice.milliseconds,
              label: Text('Milissegundos'),
            ),
          ],
          selected: {_unit},
          onSelectionChanged: (selection) =>
              setState(() => _unit = selection.first),
        ),
        OutlinedButton(onPressed: _now, child: const Text('Agora')),
      ],
      result: switch (parsed) {
        null => null,
        Err(:final error) => StatusMessage(tone: Tone.error, message: error),
        Ok(:final value) => _TimestampResults(
          parsed: value,
          auto: _unit == UnitChoice.auto,
        ),
      },
    );
  }
}

class _TimestampResults extends StatelessWidget {
  const _TimestampResults({required this.parsed, required this.auto});

  final ParsedTimestamp parsed;
  final bool auto;

  @override
  Widget build(BuildContext context) {
    final ms = parsed.milliseconds;
    return Column(
      children: [
        ResultRow(
          label: 'Interpretado como',
          value: '${parsed.unit.label}${auto ? ' (detectado)' : ''}',
        ),
        ResultRow(
          label: 'UTC',
          value: formatDateTime(ms, Zone.utc),
          copyLabel: 'Copiar UTC',
        ),
        ResultRow(
          label: 'Horário local (${formatUtcOffset(ms)})',
          value: formatDateTime(ms, Zone.local),
          copyLabel: 'Copiar horário local',
        ),
        ResultRow(
          label: 'ISO 8601',
          value: formatIsoUtc(ms),
          copyLabel: 'Copiar ISO 8601',
        ),
        ResultRow(label: 'Relativo', value: formatRelative(ms)),
        ResultRow(
          label: 'Em segundos',
          value: '${toUnixSeconds(ms)}',
          copyLabel: 'Copiar em segundos',
        ),
        ResultRow(
          label: 'Em milissegundos',
          value: '$ms',
          copyLabel: 'Copiar em milissegundos',
        ),
      ],
    );
  }
}

class _DateToTimestamp extends StatefulWidget {
  const _DateToTimestamp();

  @override
  State<_DateToTimestamp> createState() => _DateToTimestampState();
}

class _DateToTimestampState extends State<_DateToTimestamp> {
  Zone _zone = Zone.local;
  final _input = TextEditingController(
    text: formatDateTime(_nowInSeconds() * 1000, Zone.local),
  );

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _now() {
    setState(() => _input.text = formatDateTime(_nowInSeconds() * 1000, _zone));
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _input.text.trim().isEmpty
        ? null
        : parseDateTime(_input.text, _zone);
    return _Card(
      title: 'Data → timestamp',
      controls: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _input,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Data e hora',
              hintText: '2024-10-17 00:00:00',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SegmentedButton<Zone>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: Zone.local, label: Text('Local')),
            ButtonSegment(value: Zone.utc, label: Text('UTC')),
          ],
          selected: {_zone},
          onSelectionChanged: (selection) =>
              setState(() => _zone = selection.first),
        ),
        OutlinedButton(onPressed: _now, child: const Text('Agora')),
      ],
      result: switch (parsed) {
        null => null,
        Err(:final error) => StatusMessage(tone: Tone.error, message: error),
        Ok(:final value) => Column(
          children: [
            if (value.explicitZone)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: StatusMessage(
                  tone: Tone.info,
                  message:
                      'O texto já informa o fuso (Z ou ±hh:mm), então a opção Local/UTC foi ignorada.',
                ),
              ),
            ResultRow(
              label: 'Segundos',
              value: '${toUnixSeconds(value.milliseconds)}',
              copyLabel: 'Copiar segundos',
            ),
            ResultRow(
              label: 'Milissegundos',
              value: '${value.milliseconds}',
              copyLabel: 'Copiar milissegundos',
            ),
            ResultRow(
              label: 'ISO 8601 (UTC)',
              value: formatIsoUtc(value.milliseconds),
              copyLabel: 'Copiar ISO 8601',
            ),
          ],
        ),
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.controls, this.result});

  final String title;
  final List<Widget> controls;
  final Widget? result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            ),
            if (result != null) ...[const SizedBox(height: 12), result!],
          ],
        ),
      ),
    );
  }
}
