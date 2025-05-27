import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final List<String> friends;
  final List<String> groups;
  final DateTime createdAt;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.friends,
    required this.groups,
    required this.createdAt,
    this.settings,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      friends: List<String>.from(map['friends'] ?? []),
      groups: List<String>.from(map['groups'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      settings: map['settings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'friends': friends,
      'groups': groups,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    List<String>? friends,
    List<String>? groups,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      friends: friends ?? this.friends,
      groups: groups ?? this.groups,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }
}