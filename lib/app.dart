import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'routing/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/constants/app_constants.dart';

/// Root application widget
/// Configures Material 3 theme, routing, and responsive behavior
class FurrowApp extends ConsumerStatefulWidget {
  const FurrowApp({super.key});

  @override
  ConsumerState<FurrowApp> createState() => _FurrowAppState();
}

class _FurrowAppState extends ConsumerState<FurrowApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
    if (!done && mounted) {
      appRouter.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Earthy Material 3 theme
      theme: FurrowTheme.light,
      darkTheme: FurrowTheme.dark,
      themeMode: themeMode,

      // GoRouter configuration
      routerConfig: appRouter,
    );
  }
}
