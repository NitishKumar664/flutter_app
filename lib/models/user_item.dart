class UserItem {
  final String username;
  final String role; // owner | admin | viewer
  final bool builtin; // true only for the primary owner account — can't be deleted
  final DateTime? createdAt;

  UserItem({
    required this.username,
    required this.role,
    this.builtin = false,
    this.createdAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      username: json['username'] as String? ?? 'unknown',
      role: json['role'] as String? ?? 'viewer',
      builtin: json['builtin'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
