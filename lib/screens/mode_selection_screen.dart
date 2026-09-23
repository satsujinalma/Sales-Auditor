import 'package:flutter/material.dart';
import 'admin/admin_dashboard_screen.dart';
import 'shopkeeper/shopkeeper_sales_screen.dart';

enum AppMode {
  shopkeeper,
  admin,
}

class ModeSelectionScreen extends StatefulWidget {
  final AppMode initialMode;

  const ModeSelectionScreen({
    super.key,
    this.initialMode = AppMode.shopkeeper,
  });

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late AppMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMode == AppMode.shopkeeper) {
      return ShopkeeperSalesScreen(
        onSwitchToAdmin: () => setState(() => _currentMode = AppMode.admin),
      );
    } else {
      return AdminDashboardScreen(
        onSwitchToShopkeeper: () =>
            setState(() => _currentMode = AppMode.shopkeeper),
      );
    }
  }
}
