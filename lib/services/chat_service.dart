import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import 'api_client.dart';
import 'file_service.dart';

class ChatService {
  Dio get _dio => ApiClient.instance.dio;

  /// GET /api/messages
  Future<List<ChatMessage>> listMessages() async {
    final res = await _dio.get('/api/messages');
    _throwIfError(res);
    final list = res.data as List;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .where((m) => !m.deleted)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// POST /api/messages — text-only for now (no attachments/replies in this batch).
  Future<ChatMessage> sendMessage(String text) async {
    final res = await _dio.post('/api/messages', data: {'text': text});
    _throwIfError(res);
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
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
