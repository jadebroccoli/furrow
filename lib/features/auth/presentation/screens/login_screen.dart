import 'package:flutter/material.dart';

/// Login screen for Supabase Auth
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App icon / logo placeholder
              Icon(
                Icons.yard,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Furrow',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Track your garden from seed to harvest',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Email field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Sign in button
              FilledButton(
                onPressed: () {
                  // TODO: Supabase sign in
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 12),

              // Sign up link
              TextButton(
                onPressed: () {
                  // TODO: Navigate to register screen
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),

              const SizedBox(height: 24),

              // Skip / continue without account
              OutlinedButton(
                onPressed: () {
                  // TODO: Continue without account (local-only mode)
                },
                child: const Text('Continue without account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
