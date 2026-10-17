import 'package:flutter/material.dart';

enum Tone { error, success, warning, info }

/// Status box. The tone is shown by icon and text, never by color alone, and
/// screen readers announce changes (live region).
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.tone,
    this.title,
    this.message,
    this.details,
  });

  final Tone tone;
  final String? title;
  final String? message;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = switch (tone) {
      Tone.error => (Icons.error_outline, scheme.error),
      Tone.success => (
        Icons.check_circle_outline,
        dark ? Colors.green.shade300 : Colors.green.shade800,
      ),
      Tone.warning => (
        Icons.warning_amber_rounded,
        dark ? Colors.amber.shade300 : Colors.orange.shade900,
      ),
      Tone.info => (Icons.info_outline, scheme.primary),
    };
    final text = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: text.titleSmall?.copyWith(color: color),
                    ),
                  if (message != null) Text(message!, style: text.bodyMedium),
                  ?details,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
