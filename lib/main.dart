import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'widgets/hearth_ui.dart';
import 'widgets/hearth_pulse_drawer.dart';
import 'screens/budget_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/cleaning_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'models/meal_models.dart';
import 'providers/budget_provider.dart';
import 'providers/meals_provider.dart';
import 'providers/cleaning_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notifications_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  await container.read(pushNotificationServiceProvider).initializeLocalNotifications();
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

  String _getPageTitle(String path) {
    switch (path) {
      case '/budget':
        return 'Budżet';
      case '/inventory':
        return 'Spiżarnia';
      case '/meals':
        return 'Posiłki';
      case '/cleaning':
        return 'Sprzątanie';
      case '/settings':
        return 'Ustawienia';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const LoginScreen();
    }

    final unreadCount = ref.watch(notificationsStreamProvider.select((asyncList) {
      final list = asyncList.value;
      if (list == null) {
        return 0;
      }
      return list.where((n) => !n.readBy.contains(currentUser.name)).length;
    }));

    final mealPlans = ref.watch(mealPlanProvider).value ?? [];
    final recipes = ref.watch(recipesProvider).value ?? [];
    final chores = ref.watch(cleaningProvider).value ?? [];
    final inventory = ref.watch(inventoryProvider).value ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentUser.notificationsEnabled) {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final todayPlan = mealPlans.where((p) => p.id == todayStr).firstOrNull;
        final Recipe? todaysRecipe = todayPlan?.recipeId != null
            ? recipes.where((r) => r.id == todayPlan!.recipeId).firstOrNull
            : null;

        final myChoresCount = chores
            .where((c) => !c.isDone && c.assignee.toLowerCase() == currentUser.name.toLowerCase())
            .length;

        final lowStock = inventory.where((i) => i.isRunningLow).toList();

        ref.read(pushNotificationServiceProvider).syncScheduledDeviceNotifications(
          todaysRecipe: todaysRecipe,
          choresCount: myChoresCount,
          lowStockItems: lowStock,
        );
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;
    final pageTitle = _getPageTitle(currentPath);

    final navItems = const [
      (id: 'Przegląd', path: '/', icon: Icons.home_outlined, activeIcon: Icons.home),
      (id: 'Budżet', path: '/budget', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet),
      (id: 'Spiżarnia', path: '/inventory', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2),
      (id: 'Posiłki', path: '/meals', icon: Icons.soup_kitchen_outlined, activeIcon: Icons.soup_kitchen),
      (id: 'Sprzątanie', path: '/cleaning', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome),
    ];

    final horizontalPadding = isDesktop ? 48.0 : (isMobile ? 16.0 : 24.0);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      endDrawer: HearthPulseDrawer(currentUser: currentUser),
      body: Container(
        decoration: AppTheme.canvasGradientDecoration,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Sticky Top Navigation Header
              RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(247, 245, 240, 0.85),
                    border: Border(bottom: BorderSide(color: AppTheme.line)),
                  ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isDesktop ? 16.0 : 12.0,
                      ),
                      child: Row(
                        children: [
                          // Brand Title
                          GestureDetector(
                            onTap: () => context.go('/'),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Hearth',
                                    style: AppTheme.titleStyle(fontSize: isDesktop ? 32 : 26),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: AppTheme.titleStyle(fontSize: isDesktop ? 32 : 26, color: AppTheme.terra),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Desktop / Tablet Center Navigation Pills
                          if (!isMobile) ...[
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppTheme.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: navItems.map((item) {
                                      final isSelected = currentPath == item.path;
                                      return GestureDetector(
                                        onTap: () => context.go(item.path),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.moss : Colors.transparent,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            item.id,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : AppTheme.muted,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Spacer(),
                          ],

                          // Hearth Pulse Bell Icon
                          Builder(
                            builder: (scaffoldContext) {
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: IconButton(
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        unreadCount > 0
                                            ? Icons.notifications_active_outlined
                                            : Icons.notifications_none_rounded,
                                        size: 20,
                                        color: unreadCount > 0 ? AppTheme.moss : AppTheme.muted,
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.danger,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 14,
                                              minHeight: 14,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              unreadCount > 9 ? '9+' : '$unreadCount',
                                              style: AppTheme.monoSmall.copyWith(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  splashRadius: 18,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                  tooltip: 'Hearth Pulse',
                                  onPressed: () {
                                    Scaffold.of(scaffoldContext).openEndDrawer();
                                  },
                                ),
                              );
                            },
                          ),

                          // Profile Pill
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => context.go('/settings'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      HearthAvatar(
                                        name: currentUser.name,
                                        color: currentUser.color,
                                        avatar: currentUser.avatar,
                                        size: 30,
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(width: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 120),
                                          child: Text(
                                            currentUser.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ] else ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.settings_outlined, size: 16, color: AppTheme.muted),
                                        const SizedBox(width: 4),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout, size: 16, color: AppTheme.muted),
                                  splashRadius: 16,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  tooltip: 'Zablokuj ekran',
                                  onPressed: () => ref.read(currentUserProvider.notifier).logout(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ),

              // Main Content Area
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isDesktop ? 32.0 : 20.0,
                        horizontalPadding,
                        isMobile ? 12.0 : 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pageTitle.isNotEmpty && currentPath != '/settings') ...[
                            Text(
                              pageTitle,
                              style: AppTheme.titleStyle(fontSize: isDesktop ? 44 : 32),
                            ),
                            SizedBox(height: isDesktop ? 28 : 20),
                          ],
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Mobile Bottom Navigation Bar (< 600px)
              if (isMobile)
                RepaintBoundary(
                  child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.92),
                    border: Border(top: BorderSide(color: AppTheme.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: navItems.map((item) {
                          final isSelected = currentPath == item.path;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => context.go(item.path),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.sage.withValues(alpha: 0.4) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      size: 18,
                                      color: isSelected ? AppTheme.moss : AppTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.id,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? AppTheme.moss : AppTheme.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}