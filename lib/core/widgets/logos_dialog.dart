import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/logos_theme.dart';

/// App-styled dialog used for confirmations and short inputs, so dialogs match
/// the rest of the design instead of the stock Material look.
Future<T?> showLogosDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
  T? Function()? onConfirm,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;
      final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
      return Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(message, style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: ink.withValues(alpha: 0.75))),
              ],
              if (content != null) ...[const SizedBox(height: 14), content],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(cancelLabel, style: GoogleFonts.inter(color: ink.withValues(alpha: 0.7))),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: destructive ? const Color(0xFFDC2626) : LogosColors.coral,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx, onConfirm?.call()),
                    child: Text(confirmLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
