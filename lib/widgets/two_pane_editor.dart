import 'package:flutter/material.dart';

/// Input and output side by side on wide screens, stacked on narrow ones.
/// [status] (validation message) stays right below the input.
class TwoPaneEditor extends StatelessWidget {
  const TwoPaneEditor({
    super.key,
    required this.input,
    required this.output,
    this.status,
  });

  final Widget input;
  final Widget output;
  final Widget? status;

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: input),
                    if (status != null) ...[
                      const SizedBox(height: 12),
                      status!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(child: output),
            ],
          );
        }
        return ListView(
          children: [
            SizedBox(height: 240, child: input),
            if (status != null) ...[const SizedBox(height: 12), status!],
            const SizedBox(height: _gap),
            SizedBox(height: 240, child: output),
            const SizedBox(height: _gap),
          ],
        );
      },
    );
  }
}
