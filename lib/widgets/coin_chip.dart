import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CoinType {
  fcoin('Fcoin', 'Free Coin', Icons.monetization_on_rounded, AppColors.gold),
  dcoin('Dcoin', 'Deposit Coin', Icons.diamond_rounded, AppColors.cyan),
  wcoin('Wcoin', 'Winning Coin', Icons.workspace_premium_rounded,
      AppColors.teal);

  final String label;
  final String fullName;
  final IconData icon;
  final Color color;
  const CoinType(this.label, this.fullName, this.icon, this.color);
}

String formatCoin(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

class CoinChip extends StatelessWidget {
  final CoinType type;
  final num value;
  const CoinChip({super.key, required this.type, required this.value});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: type.label,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 90),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.slate.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: type.color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 16, color: type.color),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCoin(value),
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontFamily: AppFonts.heading,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}