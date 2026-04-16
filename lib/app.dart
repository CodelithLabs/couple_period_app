import 'package:couple_period_app/core/theme/app_theme.dart';
import 'package:couple_period_app/core/widgets/app_loading_view.dart';
import 'package:couple_period_app/features/auth/provider/auth_provider.dart';
import 'package:couple_period_app/features/auth/ui/sign_in_screen.dart';
import 'package:couple_period_app/features/home/ui/home_screen.dart';
import 'package:couple_period_app/features/onboarding/provider/onboarding_provider.dart';
import 'package:couple_period_app/features/onboarding/ui/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CouplePeriodApp extends StatelessWidget {
  const CouplePeriodApp({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Couple Period Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: AppGate(bootstrapError: bootstrapError),
    );
  }
}

class AppGate extends ConsumerWidget {
  const AppGate({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bootstrapError != null) {
      return _SetupRequiredScreen(error: bootstrapError.toString());
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const SignInScreen();
        }

        final onboardingStatus = ref.watch(
          onboardingCompletionProvider(firebaseUser.uid),
        );

        return onboardingStatus.when(
          data: (isComplete) {
            if (!isComplete) {
              return OnboardingScreen(userId: firebaseUser.uid);
            }
            return const HomeScreen();
          },
          error: (error, _) {
            return _SetupRequiredScreen(
              error: 'Unable to load onboarding state: $error',
            );
          },
          loading: AppLoadingView.new,
        );
      },
      error: (error, _) {
        return _SetupRequiredScreen(
          error: 'Auth initialization failed: $error',
        );
      },
      loading: AppLoadingView.new,
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                'Firebase setup is incomplete.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
