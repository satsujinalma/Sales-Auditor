import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../mode_selection_screen.dart';
import 'phone_login_screen.dart';
import 'profile_onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
      );
    }

    // Step 1: Not logged in -> Show Phone Login Screen
    if (!authProvider.isAuthenticated) {
      return const PhoneLoginScreen();
    }

    // Step 2: Fresh user (Profile not complete) -> Show Profile & Store Onboarding Screen
    if (!authProvider.isProfileComplete) {
      return const ProfileOnboardingScreen();
    }

    // Step 3: Existing / Completed user -> Show App based on user role
    final currentUser = authProvider.currentUser;
    return ModeSelectionScreen(
      initialMode: currentUser?.role == UserRole.admin
          ? AppMode.admin
          : AppMode.shopkeeper,
    );
  }
}
