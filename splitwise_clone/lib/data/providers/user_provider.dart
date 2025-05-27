import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  
  List<UserModel> _searchResults = [];
  List<UserModel> _friends = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get searchResults => _searchResults;
  List<UserModel> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _error = null;
      
      _searchResults = await _userRepository.searchUsers(query);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFriends(List<String> friendIds) async {
    try {
      _setLoading(true);
      _friends = [];
      
      for (String friendId in friendIds) {
        final user = await _userRepository.getUser(friendId);
        if (user != null) {
          _friends.add(user);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addFriend(String userId, String friendId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _userRepository.addFriend(userId, friendId);
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFriend(String userId, String friendId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _userRepository.removeFriend(userId, friendId);
      
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

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}