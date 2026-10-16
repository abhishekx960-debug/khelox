import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/khelox_app_bar.dart';

// TODO: apni real details daalo
const String kSupportEmail = 'support@khelox.com';
const String kSupportWhatsapp = '+91 00000 00000';
const String kSupportHours = '10:00 AM - 8:00 PM (IST)';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'Fcoin, Dcoin aur Wcoin kya hai?',
      'Fcoin = Free Coin (free games se milta hai). '
          'Dcoin = Deposit Coin (deposit se aata hai). '
          'Wcoin = Winning Coin (match jeetne pe milta hai).',
    ),
    (
      'Mera balance update nahi hua',
      'Wallet screen me neeche kheench kar refresh karo. '
          'Phir bhi na dikhe to support se contact karo.',
    ),
    (
      'Password ya login problem hai',
      'Sahi email aur password check karo. Dikkat rahe to apne registered '
          'email se hume likho.',
    ),
    (
      'Match me problem aayi',
      'Match ka naam, time aur screenshot ke saath support ko message bhejo.',
    ),
  ];

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showMsg(context, '$label copy ho gaya');
  }

  Widget _contactCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.slate.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () => _copy(context, label, value),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(
              label,
              style: const TextStyle(
                color: AppColors.mist,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            subtitle: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: const Icon(Icons.copy_rounded,
                size: 20, color: AppColors.mist),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kheloxAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'CUSTOMER SUPPORT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Koi problem hai? Hum madad ke liye hain.',
            style: TextStyle(color: AppColors.mist),
          ),
          const SizedBox(height: 20),
          _contactCard(
            context,
            icon: Icons.mail_outline_rounded,
            color: AppColors.gold,
            label: 'EMAIL',
            value: kSupportEmail,
          ),
          _contactCard(
            context,
            icon: Icons.chat_outlined,
            color: const Color(0xFF6FB3A8),
            label: 'WHATSAPP',
            value: kSupportWhatsapp,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 24),
            child: Row(
              children: const [
                Icon(Icons.schedule_rounded, size: 16, color: AppColors.mist),
                SizedBox(width: 6),
                Text(
                  'Support time: $kSupportHours',
                  style: TextStyle(color: AppColors.mist, fontSize: 13),
                ),
              ],
            ),
          ),
          const Text(
            'FAQ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.slate.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (var i = 0; i < _faqs.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: AppColors.teal.withValues(alpha: 0.3),
                        ),
                      ExpansionTile(
                        iconColor: AppColors.gold,
                        collapsedIconColor: AppColors.mist,
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedAlignment: Alignment.centerLeft,
                        title: Text(
                          _faqs[i].$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        children: [
                          Text(
                            _faqs[i].$2,
                            style: const TextStyle(
                              color: AppColors.mist,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}