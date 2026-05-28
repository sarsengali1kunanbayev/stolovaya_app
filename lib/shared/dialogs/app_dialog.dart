import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../widgets/glass_card.dart';

// ─── Базовый диалог в стиле приложения ───────────────────────────────────────
class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final IconData? titleIcon;
  final Color? accentColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.titleIcon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.neonCyan;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        borderRadius: 20,
        glowColor: accent,
        shimmerBorder: true,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(titleIcon, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close,
                          color: AppColors.textSecondary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Контент
            Padding(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
            // Кнопки
            if (actions != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: actions!
                      .map((a) => Expanded(child: a))
                      .toList()
                      .expand((e) => [e, const SizedBox(width: 12)])
                      .take(actions!.length * 2 - 1)
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? titleIcon,
    Color? accentColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => AppDialog(
        title: title,
        content: content,
        actions: actions,
        titleIcon: titleIcon,
        accentColor: accentColor,
      ),
    );
  }
}

// ─── Диалог подтверждения ─────────────────────────────────────────────────────
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Подтвердить',
  Color confirmColor = AppColors.neonRed,
  IconData icon = Icons.warning_amber_rounded,
}) async {
  final result = await AppDialog.show<bool>(
    context: context,
    title: title,
    titleIcon: icon,
    accentColor: confirmColor,
    content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context, false),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          foregroundColor: AppColors.bgDeep,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: confirmColor.withOpacity(0.4),
        ),
        child: Text(confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
  return result ?? false;
}

// ─── Стилизованное поле ввода для диалогов ───────────────────────────────────
class DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? hint;
  final IconData? icon;

  const DialogTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18) : null,
          ),
        ),
      ],
    );
  }
}
