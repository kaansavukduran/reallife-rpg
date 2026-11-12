import 'package:flutter/material.dart';

/// Scroll the entire form in very short windows; otherwise keep actions visible.
/// Dialog's inset animation can briefly leave less room than its action row.
class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.width = 460,
  });
  final String title;
  final Widget content;
  final List<Widget> actions;
  final double width;
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final padding = narrow ? 12.0 : 24.0;
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 16),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 20),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!,
            child: content,
          ),
        ),
      ],
    );
    final buttons = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: 8,
        overflowSpacing: 8,
        children: actions,
      ),
    );
    return Dialog(
      constraints: BoxConstraints(minWidth: 0, maxWidth: width + padding * 2),
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 40,
        vertical: 12,
      ),
      insetAnimationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 100),
      child: LayoutBuilder(
        builder: (context, c) => c.maxHeight < 240
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [form, buttons],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: SingleChildScrollView(child: form)),
                  buttons,
                ],
              ),
      ),
    );
  }
}
