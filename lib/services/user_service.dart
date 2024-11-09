import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/services/api_service.dart';


class UserService {
  final ApiService _apiService = ApiService();

  Future<List<User>> getUsers() async {
    final usersJson = await _apiService.get('users');
    return (usersJson as List).map((json) => User.fromJson(json)).toList();
  }

  Future<User> createUser(User user) async {
    final createdUserJson = await _apiService.post('users', user.toJson());
    return User.fromJson(createdUserJson);
  }
}