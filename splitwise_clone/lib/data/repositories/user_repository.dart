import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения пользователя: $e');
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + 'z')
          .limit(10)
          .get();

      final nameQuery = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(10)
          .get();

      final users = <String, UserModel>{};
      
      for (var doc in emailQuery.docs) {
        users[doc.id] = UserModel.fromMap(doc.data(), doc.id);
      }
      
      for (var doc in nameQuery.docs) {
        users[doc.id] = UserModel.fromMap(doc.data(), doc.id);
      }

      return users.values.toList();
    } catch (e) {
      throw Exception('Ошибка поиска пользователей: $e');
    }
  }

  Future<void> addFriend(String userId, String friendId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayUnion([friendId])
    });
    
    await _firestore.collection('users').doc(friendId).update({
      'friends': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> removeFriend(String userId, String friendId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayRemove([friendId])
    });
    
    await _firestore.collection('users').doc(friendId).update({
      'friends': FieldValue.arrayRemove([userId])
    });
  }
}