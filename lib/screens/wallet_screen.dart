import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';

class WalletScreen extends StatelessWidget {
  final UserModel user;
  const WalletScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final items = <(CoinType, double)>[
      (CoinType.fcoin, user.fcoin),
      (CoinType.dcoin, user.dcoin),
      (CoinType.wcoin, user.wcoin),
    ];

    return Scaffold(
      appBar: const KheloxAppBar('Wallet'),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await UserStore.instance.refresh(silent: false);
          } catch (e) {
            if (context.mounted) showMsg(context, 'Refresh fail: $e');
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const Text(
              'AAPKA BALANCE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 16),
            for (final it in items)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.surfaceCard(
                  border: it.$1.color.withValues(alpha: 0.45),
                  radius: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: it.$1.color.withValues(alpha: 0.15),
                      ),
                      child: Icon(it.$1.icon, color: it.$1.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.$1.fullName.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.mist,
                              fontSize: 12.5,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatCoin(it.$2),
                            style: TextStyle(
                              color: it.$1.color,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      it.$1.label,
                      style: const TextStyle(
                        color: AppColors.mist,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}