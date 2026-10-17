import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../theme.dart';
import '../../widgets/code_field.dart';
import '../../widgets/copy_button.dart';
import '../../widgets/result_row.dart';
import '../../widgets/status_message.dart';
import '../timestamp/timestamp_converter.dart';
import 'jwt_decoder.dart';

class JwtPage extends StatefulWidget {
  const JwtPage({super.key});

  @override
  State<JwtPage> createState() => _JwtPageState();
}

class _JwtPageState extends State<JwtPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _input.text.trim().isEmpty ? null : decodeJwt(_input.text);
    return ListView(
      children: [
        const StatusMessage(
          tone: Tone.warning,
          title: 'Somente decodificação: a assinatura não é verificada',
          message:
              'Qualquer pessoa consegue montar um token com esse conteúdo; não confie nele '
              'sem validar a assinatura no servidor. O token é lido apenas no seu dispositivo '
              'e nunca é enviado a servidores.',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: CodeField(
            label: 'Token JWT',
            controller: _input,
            onChanged: (_) => setState(() {}),
            hintText:
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0In0.…',
            hasError: result is Err,
            actions: [
              ClearButton(
                onPressed: _input.text.isEmpty
                    ? null
                    : () => setState(_input.clear),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...switch (result) {
          null => const <Widget>[],
          Err(:final error) => [
            StatusMessage(
              tone: Tone.error,
              title: 'Não foi possível decodificar',
              message: error,
            ),
          ],
          Ok(:final value) => [
            _TimingMessage(payload: value.payload.claims),
            const SizedBox(height: 16),
            _DecodedToken(token: value),
          ],
        },
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TimingMessage extends StatelessWidget {
  const _TimingMessage({required this.payload});

  final Map<String, Object?> payload;

  String _relative(String claim) {
    final seconds = payload[claim];
    return seconds is num ? formatRelative((seconds * 1000).round()) : '';
  }

  @override
  Widget build(BuildContext context) {
    return switch (tokenTiming(payload)) {
      TokenTiming.expired => StatusMessage(
        tone: Tone.warning,
        title: 'Expirado',
        message: 'Pelo campo exp, o token expirou ${_relative('exp')}.',
      ),
      TokenTiming.notYetValid => StatusMessage(
        tone: Tone.warning,
        title: 'Ainda não válido',
        message: 'Pelo campo nbf, o token só vale ${_relative('nbf')}.',
      ),
      TokenTiming.active => StatusMessage(
        tone: Tone.success,
        title: 'Dentro do prazo',
        message: 'Expira ${_relative('exp')}.',
      ),
      TokenTiming.noExpiry => const StatusMessage(
        tone: Tone.info,
        message: 'O token não tem data de expiração (exp).',
      ),
    };
  }
}

class _DecodedToken extends StatelessWidget {
  const _DecodedToken({required this.token});

  final DecodedJwt token;

  @override
  Widget build(BuildContext context) {
    final claims = timeClaims(token.payload.claims);
    final algorithm = token.header.claims['alg'];
    final unsigned = algorithm == 'none' || token.signature.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final header = _JsonCard(title: 'Header', json: token.header.json);
            final payload = _JsonCard(
              title: 'Payload',
              json: token.payload.json,
            );
            if (constraints.maxWidth < 720) {
              return Column(
                children: [header, const SizedBox(height: 16), payload],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                Expanded(child: payload),
              ],
            );
          },
        ),
        if (claims.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Datas',
            child: Column(
              children: [
                for (final claim in claims)
                  ResultRow(
                    label: '${claim.label} (${claim.name})',
                    value: _describeDate(claim.seconds),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _Section(
          title: 'Assinatura',
          badge: 'não verificada',
          action: CopyButton(text: token.signature),
          child: unsigned
              ? const StatusMessage(
                  tone: Tone.warning,
                  message:
                      'Token sem assinatura (alg: none). Servidores não devem aceitar tokens assim.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Algoritmo declarado no header: $algorithm'),
                    const SizedBox(height: 8),
                    SelectableText(
                      token.signature,
                      style: codeStyle(context, fontSize: 12),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _describeDate(num seconds) {
    final ms = (seconds * 1000).round();
    return '${formatDateTime(ms, Zone.local)} (${formatRelative(ms)})';
  }
}

class _JsonCard extends StatelessWidget {
  const _JsonCard({required this.title, required this.json});

  final String title;
  final String json;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      action: CopyButton(text: json),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(json, style: codeStyle(context)),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.action,
    this.badge,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(badge!),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const Spacer(),
                ?action,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
