import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final List<String> members;
  final Map<String, String> roles; // userId: role (admin, member)
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final Map<String, dynamic>? settings;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    required this.members,
    required this.roles,
    required this.createdBy,
    required this.createdAt,
    this.lastActivityAt,
    this.settings,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      photoUrl: map['photoUrl'],
      members: List<String>.from(map['members'] ?? []),
      roles: Map<String, String>.from(map['roles'] ?? {}),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActivityAt: map['lastActivityAt'] != null
          ? (map['lastActivityAt'] as Timestamp).toDate()
          : null,
      settings: map['settings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'members': members,
      'roles': roles,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': lastActivityAt != null
          ? Timestamp.fromDate(lastActivityAt!)
          : null,
      'settings': settings,
    };
  }

  bool isAdmin(String userId) => roles[userId] == 'admin';
  bool isMember(String userId) => members.contains(userId);
}