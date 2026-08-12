class FolderItem {
  final String id;
  final String name;
  final String source; // admin | shared
  final bool hasPassword;
  final DateTime createdAt;

  FolderItem({
    required this.id,
    required this.name,
    required this.source,
    required this.hasPassword,
    required this.createdAt,
  });

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled folder',
      source: json['source'] as String? ?? 'admin',
      hasPassword: json['hasPassword'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
