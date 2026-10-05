// lib/main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ядро стейт-менеджера
import 'screens/inventory_screen.dart'; // Твой новый интерфейс
import 'screens/meals_screen.dart';
import 'screens/cleaning_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/overview_screen.dart';

void main() {
 runApp(
  const ProviderScope(
    child: HearthApp(),
  ),
);
}

class HearthApp extends StatelessWidget {
  const HearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hearth',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Настройка GoRouter с ShellRoute для сохранения верхней навигации
final _router = GoRouter(
  initialLocation: '/overview',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/overview',
          builder: (context, state) => const OverviewScreen(),
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(), // Здесь вызывается твой интерфейс
        ),
        GoRoute(
          path: '/meals',
          builder: (context, state) => const MealsScreen(),
        ),
        GoRoute(
          path: '/cleaning',
          builder: (context, state) => const CleaningScreen(),
        ),
      ],
    ),
  ],
);

// Главный Scaffold с верхней панелью навигации
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Получаем текущий путь для подсветки активной вкладки
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя навигационная панель
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Логотип/Заголовок
                  Text(
                    'Hearth.',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Ссылки навигации
                  Row(
                    children: [
                      _NavItem(title: 'Overview', path: '/overview', currentPath: currentPath),
                      _NavItem(title: 'Budget', path: '/budget', currentPath: currentPath),
                      _NavItem(title: 'Inventory', path: '/inventory', currentPath: currentPath),
                      _NavItem(title: 'Meals', path: '/meals', currentPath: currentPath),
                      _NavItem(title: 'Cleaning', path: '/cleaning', currentPath: currentPath),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              // Динамический контент (экраны)
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// Компонент кнопки навигации
class _NavItem extends StatelessWidget {
  final String title;
  final String path;
  final String currentPath;

  const _NavItem({
    required this.title,
    required this.path,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path;
    
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: TextButton(
        onPressed: () => context.go(path),
        style: TextButton.styleFrom(
          backgroundColor: isActive ? AppTheme.mossGreen : Colors.transparent,
          foregroundColor: isActive ? Colors.white : AppTheme.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// Экраны-заглушки для вкладок
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Screen',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppTheme.textLight,
        ),
      ),
    );
  }
}