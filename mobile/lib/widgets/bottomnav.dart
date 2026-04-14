import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../services/localstorage.dart';
import '../services/rewardsProvider.dart';

class BottomNav extends StatelessWidget{
  final Widget child;

  const BottomNav({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(String location) {
    if (location == '/dashboard') return 0;
    if (location.startsWith('/sets')) return 1;
    if (location.startsWith('/quiz')) return 2;
    if (location.startsWith('/rewards')) return 3;
    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async{
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/sets/new');
        break;
      case 2:
        context.go('/quiz');
        break;
      case 3:
        context.go('/rewards');
        break;
    }
  }

  Future<void> _logout(BuildContext context) async{
    await LocalStorageService.remove('user_data');
    if (context.mounted){
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context){
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(location);
    final rewards = RewardsScope.of(context);
    final theme = rewards.activeTheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: theme.colors.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBar(
            height: 74,
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colors.primaryColor.withOpacity(0.22),
            selectedIndex: currentIndex,
            onDestinationSelected: (index) async{
              if (index == 4){
                //logout
                await LocalStorageService.remove('user_data');
                if (context.mounted){
                  context.go('/');
                }
                return;
              }
              _onTap(context, index);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books_rounded),
                label: 'Sets',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz_rounded),
                label: 'Quiz',
              ),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.emoji_events_outlined),
                    Positioned(
                      right: -12,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: theme.colors.primaryColor.withOpacity(0.14),
                          border: Border.all(
                            color: theme.colors.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          rewards.rewards.totalPoints.toString(),
                          style: TextStyle(
                            color: theme.colors.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                selectedIcon: const Icon(Icons.emoji_events_rounded),
                label: 'Rewards',
              ),
              const NavigationDestination(
                icon: Icon(Icons.logout_rounded, color: AppColors.error),
                label: 'Logout',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
