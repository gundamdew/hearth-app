import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/budget_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/cleaning_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'providers/budget_provider.dart';
import 'providers/meals_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  await container.read(budgetControllerProvider).initializeCategories();
  await container.read(mealsControllerProvider).initializeMealPlans();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HearthApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(currentPath: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const OverviewScreen()),
        GoRoute(path: '/budget', builder: (context, state) => const BudgetScreen()),
        GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
        GoRoute(path: '/meals', builder: (context, state) => const MealsScreen()),
        GoRoute(path: '/cleaning', builder: (context, state) => const CleaningScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);

class HearthApp extends StatelessWidget {
  const HearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hearth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

class MainScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const MainScaffold({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hearth.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 48),
                ),
                Row(
                  children: [
                    _NavItem(title: 'Settings', path: '/settings', currentPath: currentPath),
                    _NavItem(title: 'Overview', path: '/', currentPath: currentPath),
                    _NavItem(title: 'Budget', path: '/budget', currentPath: currentPath),
                    _NavItem(title: 'Inventory', path: '/inventory', currentPath: currentPath),
                    _NavItem(title: 'Meals', path: '/meals', currentPath: currentPath),
                    _NavItem(title: 'Cleaning', path: '/cleaning', currentPath: currentPath),
                    const SizedBox(width: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2))),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundColor: currentUser.color.withValues(alpha: 0.2), child: Text(currentUser.name[0], style: TextStyle(color: currentUser.color, fontSize: 10, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          Text(currentUser.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ref.read(currentUserProvider.notifier).logout(), // ИЗМЕНЕНО
                            child: const Icon(Icons.logout, size: 16, color: AppTheme.textLight),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final String path;
  final String currentPath;

  const _NavItem({required this.title, required this.path, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path;
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: GestureDetector(
        onTap: () => context.go(path),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.mossGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textLight,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}