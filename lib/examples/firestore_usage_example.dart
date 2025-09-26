import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_connection_manager.dart';
import '../widgets/firestore_connection_indicator.dart';

/// Example of how to use the new Firestore connection manager
class FirestoreUsageExample {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Example 1: Basic usage with timeout handling
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      return await FirestoreConnectionManager().executeWithTimeout(() async {
        final doc = await _firestore.collection('users').doc(userId).get();
        return doc.data();
      }, operationName: 'getUserData');
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Example 2: Using the extension methods
  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final snapshot = await _firestore.getWithTimeout(
        _firestore.collection('reports'),
        operationName: 'getReports',
      );

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting reports: $e');
      return [];
    }
  }

  /// Example 3: Writing data with timeout
  Future<bool> saveUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.docSetWithTimeout(
        _firestore.collection('users').doc(userId),
        data,
        operationName: 'saveUserData',
      );
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  /// Example 4: Using cached data fallback
  Future<Map<String, dynamic>?> getUserWithCache(String userId) async {
    return await FirestoreConnectionManager().getCachedOrFetch(
      'user_$userId',
      () async {
        final doc = await _firestore.collection('users').doc(userId).get();
        return doc.data();
      },
      operationName: 'getUserWithCache',
    );
  }
}

/// Example widget showing how to use the connection indicator
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال على استخدام Firestore'),
        actions: const [FirestoreConnectionStatus()],
      ),
      body: FirestoreConnectionIndicator(
        child: const Center(child: Text('محتوى الشاشة هنا')),
      ),
    );
  }
}

/// Example of how to wrap your existing screens
class WrappedScreen extends StatelessWidget {
  final Widget child;

  const WrappedScreen({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FirestoreConnectionIndicator(
      showIndicator: true,
      connectedColor: Colors.green,
      disconnectedColor: Colors.orange,
      child: child,
    );
  }
}
