import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/khelox_app_bar.dart';

/// Separate screen that only lists notifications.
/// Notifications are always on, so there is no toggle here.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = <(IconData, Color, String, String, String)>[
    (
      Icons.event_available_rounded,
      AppColors.gold,
      'Daily Check-in ready',
      'Your daily check-in bonus is ready to claim.',
      '2m ago',
    ),
    (
      Icons.emoji_events_rounded,
      AppColors.cyan,
      'Match won!',
      'You won a Free Fire match. Wcoins were added to your wallet.',
      '1h ago',
    ),
    (
      Icons.account_balance_wallet_rounded,
      AppColors.teal,
      'Deposit successful',
      'Rs 100 deposit successful. Your Dcoin balance was updated.',
      '5h ago',
    ),
    (
      Icons.album_rounded,
      AppColors.gold,
      'Spin Wheel available',
      'Your free spin is available now.',
      'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KheloxAppBar('Notifications'),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final n = _items[i];
          return _NotificationCard(
            icon: n.$1,
            color: n.$2,
            title: n.$3,
            message: n.$4,
            time: n.$5,
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.mist,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.mist,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
