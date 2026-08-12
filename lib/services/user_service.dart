import 'package:dio/dio.dart';
import '../models/user_item.dart';
import 'api_client.dart';
import 'file_service.dart'; // reuses FileServiceException for consistent error handling

class UserService {
  Dio get _dio => ApiClient.instance.dio;

  /// GET /api/users — owner role required (admin/viewer accounts get a 403).
  Future<List<UserItem>> listUsers() async {
    final res = await _dio.get('/api/users');
    _throwIfError(res);
    final list = res.data as List;
    return list.map((e) => UserItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/users — role must be 'admin' or 'viewer' (server defaults to
  /// 'viewer' for anything else, including 'owner' — there's only ever one owner).
  Future<void> addUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final res = await _dio.post('/api/users', data: {
      'username': username,
      'password': password,
      'role': role,
    });
    _throwIfError(res);
  }

  /// DELETE /api/users/:username
  Future<void> deleteUser(String username) async {
    final res = await _dio.delete('/api/users/$username');
    _throwIfError(res);
  }

  void _throwIfError(Response res) {
    if (res.statusCode == null || res.statusCode! >= 400) {
      final message = (res.data is Map && res.data['error'] != null)
          ? res.data['error'].toString()
          : 'Request failed (${res.statusCode})';
      throw FileServiceException(message, statusCode: res.statusCode);
    }
  }
}
