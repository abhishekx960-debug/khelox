import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/api_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'wallet_screen.dart';

class MainShell extends StatefulWidget {
  final UserModel user;
  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0; // 0 Home, 1 Wallet, 2 Support, 3 Settings

  @override
  void initState() {
    super.initState();
    UserStore.instance.start(widget.user);
  }

  @override
  void dispose() {
    UserStore.instance.stop();
    super.dispose();
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: UserStore.instance.user,
      builder: (context, u, _) {
        final user = u ?? widget.user;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              HomeScreen(user: user),
              WalletScreen(user: user),
              const SupportScreen(),
              SettingsScreen(
                user: user,
                onOpenWallet: () => _go(1),
                onOpenSupport: () => _go(2),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: const [
              NavigationDestination(
                icon: HugeIcon(
                  icon: AppIcons.home,
                  size: 24,
                  color: AppColors.mist,
                  strokeWidth: 1.7,
                ),
                selectedIcon: HugeIcon(
                  icon: AppIcons.home,
                  size: 24,
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: HugeIcon(
                  icon: AppIcons.wallet,
                  size: 24,
                  color: AppColors.mist,
                  strokeWidth: 1.7,
                ),
                selectedIcon: HugeIcon(
                  icon: AppIcons.wallet,
                  size: 24,
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: HugeIcon(
                  icon: AppIcons.support,
                  size: 24,
                  color: AppColors.mist,
                  strokeWidth: 1.7,
                ),
                selectedIcon: HugeIcon(
                  icon: AppIcons.support,
                  size: 24,
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
                label: 'Support',
              ),
              NavigationDestination(
                icon: HugeIcon(
                  icon: AppIcons.settings,
                  size: 24,
                  color: AppColors.mist,
                  strokeWidth: 1.7,
                ),
                selectedIcon: HugeIcon(
                  icon: AppIcons.settings,
                  size: 24,
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}