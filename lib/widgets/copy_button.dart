import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies [text] to the clipboard and confirms with a snackbar.
class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.text,
    this.label = 'Copiar',
    this.iconOnly = false,
  });

  final String text;

  /// Button text, or the tooltip when [iconOnly] is true.
  final String label;
  final bool iconOnly;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copiado para a área de transferência'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = text.isEmpty ? null : () => _copy(context);
    if (iconOnly) {
      return IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: const Icon(Icons.copy_outlined, size: 20),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.copy_outlined, size: 18),
      label: Text(label),
    );
  }
}

class ClearButton extends StatelessWidget {
  const ClearButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.close, size: 18),
    label: const Text('Limpar'),
  );
}
