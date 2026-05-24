class UserProfile {
  const UserProfile({
    required this.id,
    required this.isPublic,
    this.displayName,
    this.avatarUrl,
    this.username,
  });

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? username;
  final bool isPublic;

  String get initials {
    final name = displayName ?? username ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  UserProfile copyWith({String? displayName, String? avatarUrl, String? username, bool? isPublic}) =>
      UserProfile(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        username: username ?? this.username,
        isPublic: isPublic ?? this.isPublic,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        username: json['username'] as String?,
        isPublic: json['is_public'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'username': username,
        'is_public': isPublic,
      };
}
