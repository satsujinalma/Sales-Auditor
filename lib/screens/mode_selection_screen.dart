import 'package:flutter/material.dart';
import 'admin/admin_dashboard_screen.dart';
import 'shopkeeper/shopkeeper_sales_screen.dart';

enum AppMode {
  shopkeeper,
  admin,
}

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  AppMode _currentMode = AppMode.shopkeeper;

  @override
  Widget build(BuildContext context) {
    if (_currentMode == AppMode.shopkeeper) {
      return ShopkeeperSalesScreen(
        onSwitchToAdmin: () => _promptAdminMode(context),
      );
    } else {
      return AdminDashboardScreen(
        onSwitchToShopkeeper: () {
          setState(() => _currentMode = AppMode.shopkeeper);
        },
      );
    }
  }

  void _promptAdminMode(BuildContext context) {
    setState(() => _currentMode = AppMode.admin);
  }
}
