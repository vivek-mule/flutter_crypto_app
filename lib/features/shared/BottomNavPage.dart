import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/HomePage.dart';
import '../news/NewsPage.dart';
import '../settings/SettingsPage.dart';
import '../auth/providers/auth_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({Key? key}) : super(key: key);

  static const _pages = <Widget>[
    HomePage(),
    NewsPage(),
    SettingsPage(),
  ];

  static const _labels = ['Home', 'News', 'Settings'];
  static const _icons = [Icons.home, Icons.article, Icons.settings];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final authState = ref.watch(authStateProvider);

    // If still loading auth state, show splash/loading
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If not logged in, redirect to login page
    if (authState.value == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox();
    }

    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        items: List.generate(
          _pages.length,
              (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _labels[i],
          ),
        ),
        onTap: (newIndex) {
          ref.read(bottomNavIndexProvider.notifier).state = newIndex;
        },
      ),
    );
  }
}
