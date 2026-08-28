import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openHistory() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final Widget body;
    switch (_index) {
      case 1:
        body = const HistoryTab();
        break;
      case 2:
        body = const ProfileTab();
        break;
      default:
        body = HomeTab(onOpenHistory: _openHistory);
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),

        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          child: NavigationBar(
            height: 66,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Главная',
              ),

              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon:
                    Icon(Icons.receipt_long, color: AppColors.primary),
                label: 'История',
              ),

              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Профиль',
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
