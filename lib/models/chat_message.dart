class ChatMessage {
  final String id;
  final String name;
  final String role; // admin | contributor
  final String? text;
  final bool deleted;
  final bool edited;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.name,
    required this.role,
    required this.deleted,
    required this.edited,
    required this.createdAt,
    this.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Someone',
      role: json['role'] as String? ?? 'contributor',
      text: json['text'] as String?,
      deleted: json['deleted'] as bool? ?? false,
      edited: json['edited'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  bool get isMine => role == 'admin';
}
