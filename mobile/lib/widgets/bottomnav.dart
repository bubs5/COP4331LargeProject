import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../services/localstorage.dart';

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

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
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
            indicatorColor: AppColors.primarySoft,
            selectedIndex: currentIndex,
            onDestinationSelected: (index) async{
              if (index == 3){
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
            destinations: const [
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