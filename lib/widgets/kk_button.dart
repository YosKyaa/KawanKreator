import 'package:flutter/material.dart';
import 'package:kawankreatorapps/theme.dart';

class KKButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool secondary;
  final IconData? icon;
  final String? semanticsLabel;
  final Widget? leading;

  const KKButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.secondary = false,
    this.icon,
    this.semanticsLabel,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      icon == null || leading == null,
      'Gunakan salah satu dari icon atau leading pada KKButton.',
    );
    final loaderColor = secondary ? KKColors.primary : Colors.white;
    final buttonChild = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loaderColor,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final child = Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: secondary
          ? OutlinedButton(
              onPressed: loading ? null : onPressed,
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: loading ? null : onPressed,
              child: buttonChild,
            ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: child,
    );
  }
}

class KKTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const KKTextButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: KKColors.primary),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
