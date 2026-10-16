import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'support_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // TODO: apni final policy yahan daalo (legal review ke baad).
  static const _sections = <(String, String)>[
    (
      '1. Hum kya information lete hain',
      'Registration ke time aapka naam, email, phone number aur password '
          '(encrypted form me) liya jata hai. App me aapka coin balance '
          '(Fcoin, Dcoin, Wcoin) aur game activity bhi save hoti hai.',
    ),
    (
      '2. Information ka use',
      'Aapka account chalane, login karane, coins/wallet dikhane, support '
          'dene aur app behtar banane ke liye use hota hai.',
    ),
    (
      '3. Data sharing',
      'Hum aapka personal data bechte nahi hain. Sirf kanooni zaroorat ya '
          'service chalane ke liye zaroori partners ke saath share ho sakta hai.',
    ),
    (
      '4. Security',
      'Passwords hashed form me store hote hain aur server se baat HTTPS '
          'par hoti hai. Phir bhi koi system 100% surakshit nahi hota, isliye '
          'apna password kisi ko na batayein.',
    ),
    (
      '5. Aapke adhikar',
      'Aap apna data dekhne, sahi karwane ya account delete karwane ke liye '
          'support se contact kar sakte hain.',
    ),
    (
      '6. Contact',
      'Privacy se jude sawal ke liye: $kSupportEmail',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'KheloX Privacy Policy',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aapki privacy hamare liye important hai.',
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