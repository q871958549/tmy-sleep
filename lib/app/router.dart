import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/schedule/settings_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
