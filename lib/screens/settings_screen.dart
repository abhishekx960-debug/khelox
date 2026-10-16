import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';
import 'login_screen.dart';
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
  bool _notif = true;

  @override
  void initState() {
    super.initState();
    SettingsService.notificationsOn().then((v) {
      if (mounted) setState(() => _notif = v);
    });
  }

  void _toggleNotif(bool v) {
    setState(() => _notif = v);
    SettingsService.setNotifications(v);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Kya aap logout karna chahte ho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
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
      appBar: kheloxAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Profile
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.slate.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.gold,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
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
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
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

          const _SectionLabel('WALLET'),
          _Group(children: [
            _Tile(
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.gold,
              title: 'My Wallet',
              subtitle: 'Fcoin ${formatCoin(user.fcoin)}  •  '
                  'Dcoin ${formatCoin(user.dcoin)}  •  '
                  'Wcoin ${formatCoin(user.wcoin)}',
              onTap: widget.onOpenWallet,
            ),
          ]),

          const _SectionLabel('PREFERENCES'),
          _Group(children: [
            _Tile(
              icon: Icons.notifications_rounded,
              color: AppColors.cyan,
              title: 'Notifications',
              subtitle: _notif ? 'On' : 'Off',
              onTap: () => _toggleNotif(!_notif),
              trailing: Switch(value: _notif, onChanged: _toggleNotif),
            ),
          ]),

          const _SectionLabel('HELP & LEGAL'),
          _Group(children: [
            _Tile(
              icon: Icons.support_agent_rounded,
              color: const Color(0xFF6FB3A8),
              title: 'Customer Support',
              subtitle: 'FAQ aur contact details',
              onTap: widget.onOpenSupport,
            ),
            _Tile(
              icon: Icons.privacy_tip_rounded,
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
              icon: Icons.logout_rounded,
              color: const Color(0xFFFF6B6B),
              title: 'Logout',
              titleColor: const Color(0xFFFF6B6B),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 0, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: AppColors.cyan,
        ),
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
      decoration: BoxDecoration(
        color: AppColors.slate.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 68,
                    color: AppColors.teal.withValues(alpha: 0.3),
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
  final IconData icon;
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
        ),
        child: Icon(icon, color: color, size: 22),
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
              style: const TextStyle(color: AppColors.mist, fontSize: 12),
            ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
    );
  }
}