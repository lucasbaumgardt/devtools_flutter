import 'package:flutter/material.dart';

import '../theme.dart';

/// Labelled monospace text area used for every tool input and output. It
/// fills the height its parent gives it.
class CodeField extends StatelessWidget {
  const CodeField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.readOnly = false,
    this.hintText,
    this.hasError = false,
    this.actions = const [],
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String? hintText;
  final bool hasError;

  /// Buttons shown above the field (copy, clear…).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: scheme.error, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            readOnly: readOnly,
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            style: codeStyle(context),
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: hintText,
              hintStyle: codeStyle(
                context,
              ).copyWith(color: scheme.onSurfaceVariant),
              filled: readOnly,
              fillColor: scheme.surfaceContainerLow,
              enabledBorder: hasError ? errorBorder : null,
              focusedBorder: hasError ? errorBorder : null,
            ),
          ),
        ),
      ],
    );
  }
}
