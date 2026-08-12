import 'package:dio/dio.dart';
import '../models/folder_item.dart';
import 'api_client.dart';
import 'file_service.dart'; // reuses FileServiceException for consistent error handling

class FolderService {
  Dio get _dio => ApiClient.instance.dio;

  /// GET /api/folders
  Future<List<FolderItem>> listFolders() async {
    final res = await _dio.get('/api/folders');
    _throwIfError(res);
    final list = res.data as List;
    return list.map((e) => FolderItem.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// DELETE /api/folders/:id — cascades to delete every file inside it too.
  Future<void> deleteFolder(String id) async {
    final res = await _dio.delete('/api/folders/$id');
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
