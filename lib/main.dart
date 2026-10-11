import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sales_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/firestore_sales_repository.dart';
import 'services/hybrid_auth_repository.dart';
import 'services/repository_factory.dart';
import 'services/sales_repository.dart';
import 'theme/liquid_glass_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SalesRepository? repository;
  HybridAuthRepository? authRepository;

  try {
    repository = await RepositoryFactory.createRepository();
    authRepository = HybridAuthRepository(repository);
    await authRepository.init();
  } catch (e, stack) {
    debugPrint('>>> main: Initialization error: $e\n$stack');
    repository ??= FirestoreSalesRepository();
    authRepository ??= HybridAuthRepository(repository);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository!),
        ),
        ChangeNotifierProvider(
          create: (_) => SalesProvider(repository!),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(repository!),
        ),
      ],
      child: const KeralaLotteryAuditorApp(),
    ),
  );
}

class KeralaLotteryAuditorApp extends StatelessWidget {
  const KeralaLotteryAuditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Audit - Kerala Lottery',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: LiquidGlassTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}