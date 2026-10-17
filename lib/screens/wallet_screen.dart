import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';
import 'deposit_screen.dart';
import 'transaction_history_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatelessWidget {
  final UserModel user;
  const WalletScreen({super.key, required this.user});

  void _showWithdrawOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Withdraw',
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Which coin do you want to withdraw?',
                style: TextStyle(color: AppColors.mist, fontSize: 13.5),
              ),
              const SizedBox(height: 18),
              _WithdrawOption(
                type: CoinType.fcoin,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WithdrawScreen(
                        user: user,
                        initialType: 'fcoin',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _WithdrawOption(
                type: CoinType.wcoin,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WithdrawScreen(
                        user: user,
                        initialType: 'wcoin',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'YOUR BALANCE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 16),
            _CoinRow(CoinType.fcoin, user.fcoin),
            const SizedBox(height: 18),
            _CoinRow(CoinType.dcoin, user.dcoin),
            const SizedBox(height: 18),
            _CoinRow(CoinType.wcoin, user.wcoin),
            const SizedBox(height: 28),
            Row(
              children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DepositScreen(user: user),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Deposit'),
                ),
              ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWithdrawOptions(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: const BorderSide(color: AppColors.cyan),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TransactionHistoryScreen(user: user),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Transaction History'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinRow extends StatelessWidget {
  final CoinType type;
  final double value;
  const _CoinRow(this.type, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: type.color.withValues(alpha: 0.15),
          ),
          child: Icon(type.icon, color: type.color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: const TextStyle(
                  fontFamily: AppFonts.heading,
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCoin(value),
                  style: TextStyle(
                    fontFamily: AppFonts.heading,
                    color: type.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WithdrawOption extends StatelessWidget {
  final CoinType type;
  final VoidCallback onTap;
  const _WithdrawOption({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppTheme.surfaceCard(
            border: type.color.withValues(alpha: 0.45),
            radius: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: type.color.withValues(alpha: 0.15),
                ),
                child: Icon(type.icon, color: type.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontFamily: AppFonts.heading,
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      type.fullName,
                      style: const TextStyle(
                        color: AppColors.mist,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
            ],
          ),
        ),
      ),
    );
  }
}
