import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createGroup({
    required String name,
    String? description,
    required String createdBy,
    required List<String> members,
  }) async {
    try {
      final group = GroupModel(
        id: '',
        name: name,
        description: description,
        members: members,
        roles: {createdBy: 'admin'},
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('groups').add(group.toMap());
      
      // Update users' groups
      for (String memberId in members) {
        await _firestore.collection('users').doc(memberId).update({
          'groups': FieldValue.arrayUnion([docRef.id])
        });
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания группы: $e');
    }
  }

  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения группы: $e');
    }
  }

  Future<void> updateGroup(GroupModel group) async {
    await _firestore.collection('groups').doc(group.id).update(group.toMap());
  }

  Future<void> addMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'roles.$userId': 'member',
    });

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayUnion([groupId])
    });
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
      'roles.$userId': FieldValue.delete(),
    });

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayRemove([groupId])
    });
  }

  Future<void> updateMemberRole(String groupId, String userId, String role) async {
    await _firestore.collection('groups').doc(groupId).update({
      'roles.$userId': role,
    });
  }
}