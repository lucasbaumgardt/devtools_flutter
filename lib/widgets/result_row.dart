import 'package:flutter/material.dart';

import '../theme.dart';
import 'copy_button.dart';

/// "Label / value" line with an optional copy button (Timestamp, JWT).
class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.copyLabel,
  });

  final String label;
  final String value;

  /// When set, shows a copy button with this tooltip.
  final String? copyLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: SelectableText(value, style: codeStyle(context, fontSize: 14)),
      trailing: copyLabel == null
          ? null
          : CopyButton(text: value, label: copyLabel!, iconOnly: true),
    );
  }
}
