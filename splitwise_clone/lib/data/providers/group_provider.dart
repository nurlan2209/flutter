import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../repositories/group_repository.dart';
import '../repositories/user_repository.dart';

class GroupProvider extends ChangeNotifier {
  final GroupRepository _groupRepository = GroupRepository();
  final UserRepository _userRepository = UserRepository();
  final Map<String, UserModel> _groupMembers = {};
  
  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  Map<String, UserModel> _groupMembers = {};
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  GroupModel? get selectedGroup => _selectedGroup;
  Map<String, UserModel> get groupMembers => _groupMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadUserGroups(String userId) {
    _groupRepository.getUserGroups(userId).listen((groups) {
      _groups = groups;
      notifyListeners();
    });
  }

  Future<void> createGroup({
    required String name,
    String? description,
    required String createdBy,
    required List<String> members,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _groupRepository.createGroup(
        name: name,
        description: description,
        createdBy: createdBy,
        members: members,
      );
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectGroup(String groupId) async {
    try {
      _setLoading(true);
      _selectedGroup = await _groupRepository.getGroup(groupId);
      
      if (_selectedGroup != null) {
        await _loadGroupMembers(_selectedGroup!.members);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadGroupMembers(List<String> memberIds) async {
    _groupMembers.clear();
    
    for (String memberId in memberIds) {
      final user = await _userRepository.getUser(memberId);
      if (user != null) {
        _groupMembers[memberId] = user;
      }
    }
    
    notifyListeners();
  }

  Future<void> addMember(String userId) async {
    if (_selectedGroup == null) return;
    
    try {
      _setLoading(true);
      await _groupRepository.addMember(_selectedGroup!.id, userId);
      await selectGroup(_selectedGroup!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeMember(String userId) async {
    if (_selectedGroup == null) return;
    
    try {
      _setLoading(true);
      await _groupRepository.removeMember(_selectedGroup!.id, userId);
      await selectGroup(_selectedGroup!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateMemberRole(String userId, String role) async {
    if (_selectedGroup == null) return;
    
    try {
      _setLoading(true);
      await _groupRepository.updateMemberRole(_selectedGroup!.id, userId, role);
      await selectGroup(_selectedGroup!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedGroup() {
    _selectedGroup = null;
    _groupMembers.clear();
    notifyListeners();
  }
}