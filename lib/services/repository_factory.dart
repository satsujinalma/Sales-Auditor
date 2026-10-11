import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'firestore_sales_repository.dart';
import 'sales_repository.dart';

class RepositoryFactory {
  static Future<SalesRepository> createRepository() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      debugPrint('>>> RepositoryFactory: Firebase initialized. Active apps: ${Firebase.apps.map((a) => a.name).toList()}');
    } catch (e) {
      debugPrint('>>> RepositoryFactory: Firebase init warning: $e');
    }

    try {
      final firestoreRepo = FirestoreSalesRepository();
      await firestoreRepo.init();
      debugPrint('>>> RepositoryFactory: Connected to Cloud Firestore successfully! <<<');
      return firestoreRepo;
    } catch (e, stack) {
      debugPrint('>>> RepositoryFactory: FirestoreRepo init warning ($e). Returning FirestoreSalesRepository instance.\n$stack');
      return FirestoreSalesRepository();
    }
  }
}
