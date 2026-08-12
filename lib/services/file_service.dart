import 'dart:io';
import 'package:dio/dio.dart';
import '../models/file_item.dart';
import 'api_client.dart';

class FileService {
  Dio get _dio => ApiClient.instance.dio;

  /// GET /api/files — same endpoint the web dashboard uses.
  Future<List<FileItem>> listFiles() async {
    final res = await _dio.get('/api/files');
    _throwIfError(res);
    final list = res.data as List;
    return list.map((e) => FileItem.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  /// GET /api/storage — { usedBytes, limitBytes }
  Future<(int usedBytes, int? limitBytes)> getStorage() async {
    final res = await _dio.get('/api/storage');
    _throwIfError(res);
    final data = res.data as Map<String, dynamic>;
    return (
      (data['usedBytes'] as num?)?.toInt() ?? 0,
      (data['limitBytes'] as num?)?.toInt(),
    );
  }

  /// POST /upload — multipart, field name "file" (matches multer's upload.single('file')).
  /// [onProgress] gets a 0.0–1.0 fraction.
  Future<FileItem> uploadFile(File file, {void Function(double)? onProgress}) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'visibility': 'unlisted',
    });
    final res = await _dio.post(
      '/upload',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) onProgress(sent / total);
      },
    );
    _throwIfError(res);
    return FileItem.fromJson(res.data as Map<String, dynamic>);
  }

  /// DELETE /api/files — body: { ids: [id] } (matches the web dashboard's bulk-delete endpoint).
  Future<void> deleteFile(String id) async {
    final res = await _dio.delete('/api/files', data: {'ids': [id]});
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

class FileServiceException implements Exception {
  final String message;
  final int? statusCode;
  FileServiceException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
