import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'firestore_sales_repository.dart';
import 'mock_live_sales_repository.dart';
import 'sales_repository.dart';

class RepositoryFactory {
  static Future<SalesRepository> createRepository() async {
    try {
      // Safely initialize Firebase if not already initialized by native Google Services
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }

      final firestoreRepo = FirestoreSalesRepository();
      await firestoreRepo.init();
      debugPrint('>>> RepositoryFactory: Connected to Cloud Firestore successfully! <<<');
      return firestoreRepo;
    } catch (e, stack) {
      debugPrint('>>> RepositoryFactory: Firebase init failed ($e). Falling back to MockLiveSalesRepository. <<<\n$stack');
      final mockRepo = MockLiveSalesRepository();
      await mockRepo.init();
      return mockRepo;
    }
  }
}
