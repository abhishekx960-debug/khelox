import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent_rounded),
                label: 'Support',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}