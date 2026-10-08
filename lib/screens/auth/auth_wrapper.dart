import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../mode_selection_screen.dart';
import 'pending_approval_screen.dart';
import 'phone_login_screen.dart';
import 'profile_onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE2E8F0),
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

    final currentUser = authProvider.currentUser;

    // Step 3: Non-Admin Counter Staff not approved yet -> Show Pending Approval Screen
    if (currentUser != null &&
        currentUser.role == UserRole.shopkeeper &&
        !currentUser.isApproved) {
      return PendingApprovalScreen(user: currentUser);
    }

    // Step 4: Approved Counter User or Admin -> ModeSelectionScreen
    return ModeSelectionScreen(
      initialMode: currentUser?.role == UserRole.admin
          ? AppMode.admin
          : AppMode.shopkeeper,
    );
  }
}
