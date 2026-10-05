import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sales_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/hybrid_auth_repository.dart';
import 'services/repository_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await RepositoryFactory.createRepository();
  final authRepository = HybridAuthRepository(repository);
  await authRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SalesProvider(repository),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(repository),
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // Emerald/Teal Lottery theme
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFF166534),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
