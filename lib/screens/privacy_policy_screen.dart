import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/khelox_app_bar.dart';
import 'support_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // TODO: put your final policy here (after legal review).
  static const _sections = <(String, String)>[
    (
      '1. Information We Collect',
      'During registration we collect your name, email, phone number and '
          'password (stored in encrypted form). Your coin balance '
          '(Fcoin, Dcoin, Wcoin) and game activity are also saved in the app.',
    ),
    (
      '2. How We Use Information',
      'Your information is used to run your account, log you in, show '
          'coins/wallet, provide support and improve the app.',
    ),
    (
      '3. Data Sharing',
      'We do not sell your personal data. It may be shared only when legally '
          'required or with essential partners needed to run the service.',
    ),
    (
      '4. Security',
      'Passwords are stored in hashed form and all communication with the '
          'server happens over HTTPS. No system is 100% secure, so never '
          'share your password with anyone.',
    ),
    (
      '5. Your Rights',
      'You can contact support to view, correct or delete your data, or to '
          'delete your account.',
    ),
    (
      '6. Contact',
      'For privacy-related questions: $kSupportEmail',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KheloxAppBar('Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'KheloX Privacy Policy',
            style: TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your privacy matters to us.',
            style: TextStyle(color: AppColors.mist),
          ),
          const SizedBox(height: 20),
          for (final s in _sections) ...[
            Text(
              s.$1,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.$2,
              style: const TextStyle(color: AppColors.mist, height: 1.5),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}