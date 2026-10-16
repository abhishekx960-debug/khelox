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
      appBar: kheloxAppBar(),
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
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'MY WALLET',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            for (final it in items)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.slate, Color(0xFF0B2240)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: it.$1.color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(it.$1.icon, color: it.$1.color, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.$1.fullName.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.mist,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCoin(it.$2),
                            style: TextStyle(
                              color: it.$1.color,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
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