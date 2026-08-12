// Mirrors the JSON shape returned by GET /api/files on the File Drop server
// (see server.js's sanitizeFile()). Keep this in sync if the backend's
// response shape changes.
class FileItem {
  final String id;
  final String originalName;
  final String mimetype;
  final int size;
  final String visibility; // PUBLIC | UNLISTED | PRIVATE
  final bool hasPassword;
  final int downloadCount;
  final int viewCount;
  final String? contentHash;
  final String? folderId;
  final DateTime uploadedAt;
  final DateTime? expiresAt;

  FileItem({
    required this.id,
    required this.originalName,
    required this.mimetype,
    required this.size,
    required this.visibility,
    required this.hasPassword,
    required this.downloadCount,
    required this.viewCount,
    required this.uploadedAt,
    this.contentHash,
    this.folderId,
    this.expiresAt,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as String,
      originalName: json['originalName'] as String? ?? 'Untitled',
      mimetype: json['mimetype'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
      visibility: json['visibility'] as String? ?? 'UNLISTED',
      hasPassword: json['hasPassword'] as bool? ?? false,
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      contentHash: json['contentHash'] as String?,
      folderId: json['folderId'] as String?,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ?? DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
    );
  }

  bool get isImage => mimetype.startsWith('image/');
  bool get isVideo => mimetype.startsWith('video/');
  bool get isPdf => mimetype == 'application/pdf';
}
