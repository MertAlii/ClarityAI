import 'dart:convert';

/// User profile model containing personal preferences and display info.
class UserProfile {
  final String name;
  final String preferredProvider;
  final String targetAudience;

  const UserProfile({
    required this.name,
    this.preferredProvider = 'groq',
    this.targetAudience = 'university',
  });

  /// Creates a [UserProfile] from a JSON-encoded string.
  factory UserProfile.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return UserProfile(
      name: map['name'] as String? ?? '',
      preferredProvider: map['preferredProvider'] as String? ?? 'groq',
      targetAudience: map['targetAudience'] as String? ?? 'university',
    );
  }

  /// Serializes this profile to a JSON-encoded string.
  String toJson() {
    return jsonEncode({
      'name': name,
      'preferredProvider': preferredProvider,
      'targetAudience': targetAudience,
    });
  }

  UserProfile copyWith({
    String? name,
    String? preferredProvider,
    String? targetAudience,
  }) {
    return UserProfile(
      name: name ?? this.name,
      preferredProvider: preferredProvider ?? this.preferredProvider,
      targetAudience: targetAudience ?? this.targetAudience,
    );
  }

  @override
  String toString() =>
      'UserProfile(name: $name, provider: $preferredProvider, audience: $targetAudience)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          preferredProvider == other.preferredProvider &&
          targetAudience == other.targetAudience;

  @override
  int get hashCode =>
      name.hashCode ^ preferredProvider.hashCode ^ targetAudience.hashCode;
}
