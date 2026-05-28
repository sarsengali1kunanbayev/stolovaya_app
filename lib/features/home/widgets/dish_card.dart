import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/dishes_provider.dart';

class DishCard extends StatefulWidget {
  final Dish dish;
  final bool shiftOpen;
  final VoidCallback onSell;
  final VoidCallback onAddStock;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const DishCard({
    super.key,
    required this.dish,
    required this.shiftOpen,
    required this.onSell,
    required this.onAddStock,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<DishCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  bool get isOutOfStock => widget.dish.stock <= 0;
  bool get isLowStock => widget.dish.stock > 0 && widget.dish.stock <= 3;

  Color get stockColor {
    if (isOutOfStock) return AppColors.neonRed;
    if (isLowStock) return AppColors.neonOrange;
    return AppColors.neonGreen;
  }

  void _handleTap() {
    if (!widget.shiftOpen) {
      HapticFeedback.lightImpact();
      return;
    }
    if (isOutOfStock) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    _tapController.forward().then((_) => _tapController.reverse());
    widget.onSell();
  }

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;
    final emoji = AppConstants.iconFor(dish.category);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassCard(
        onTap: _handleTap,
        onLongPress: () {
          HapticFeedback.lightImpact();
          widget.onEdit();
        },
        glowColor: isOutOfStock ? AppColors.neonRed : AppColors.neonCyan,
        shimmerBorder: isOutOfStock,
        child: Row(
          children: [
            // Эмодзи-аватар категории
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),

            // Название + категория
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${dish.price.toInt()} ₸',
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeonBadge(
                        text: dish.category,
                        color: AppColors.neonPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Остаток + действия
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Остаток
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: stockColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutOfStock ? Icons.block : Icons.inventory_2_outlined,
                        color: stockColor,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOutOfStock ? 'Нет' : '${dish.stock.toInt()} шт.',
                        style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Иконки действий
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.add_circle_outline,
                      color: AppColors.neonGreen,
                      onTap: widget.onAddStock,
                      tooltip: 'Приход',
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.neonRed,
                      onTap: widget.onDelete,
                      tooltip: 'Удалить',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
