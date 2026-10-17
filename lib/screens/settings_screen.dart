import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/khelox_app_bar.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenSupport;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.onOpenWallet,
    required this.onOpenSupport,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await SessionService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      appBar: const KheloxAppBar('Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          // Profile
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.gold,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: AppFonts.heading,
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.heading,
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.mist),
                      ),
                      Text(
                        user.phone,
                        style: const TextStyle(color: AppColors.mist),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _Group(children: [
            _Tile(
              icon: const HugeIcon(
                icon: AppIcons.wallet,
                color: AppColors.gold,
                size: 22,
                strokeWidth: 1.8,
              ),
              color: AppColors.gold,
              title: 'My Wallet',
              onTap: widget.onOpenWallet,
            ),
            _Tile(
              icon: const HugeIcon(
                icon: AppIcons.notification,
                color: AppColors.cyan,
                size: 22,
                strokeWidth: 1.8,
              ),
              color: AppColors.cyan,
              title: 'Notifications',
              subtitle: 'Always on',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
            _Tile(
              icon: const HugeIcon(
                icon: AppIcons.support,
                color: AppColors.cyan,
                size: 22,
                strokeWidth: 1.8,
              ),
              color: AppColors.cyan,
              title: 'Customer Support',
              subtitle: 'FAQ and contact details',
              onTap: widget.onOpenSupport,
            ),
            _Tile(
              icon: const Icon(
                Icons.privacy_tip_rounded,
                color: AppColors.gold,
                size: 22,
              ),
              color: AppColors.gold,
              title: 'Privacy Policy',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),
          _Group(children: [
            _Tile(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 22,
              ),
              color: AppColors.danger,
              title: 'Logout',
              titleColor: AppColors.danger,
              trailing: const SizedBox.shrink(),
              onTap: _logout,
            ),
          ]),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'KheloX v1.0.0',
              style: TextStyle(color: AppColors.mist, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 68,
                    color: AppColors.line,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String title;
  final Color titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    this.titleColor = Colors.white,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
        ),
        child: icon,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.mist, fontSize: 12.5),
            ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
    );
  }
}