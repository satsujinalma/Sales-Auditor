import 'package:firebase_core/firebase_core.dart';
import 'firestore_sales_repository.dart';
import 'mock_live_sales_repository.dart';
import 'sales_repository.dart';

class RepositoryFactory {
  static Future<SalesRepository> createRepository() async {
    try {
      // Attempt Firebase initialization
      await Firebase.initializeApp();
      final firestoreRepo = FirestoreSalesRepository();
      await firestoreRepo.init();
      return firestoreRepo;
    } catch (_) {
      // Fallback to local persistent repository if Firebase is not yet initialized with credentials
      final mockRepo = MockLiveSalesRepository();
      await mockRepo.init();
      return mockRepo;
    }
  }
}
