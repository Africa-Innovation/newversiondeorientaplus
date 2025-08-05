class UserProfile {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? series; // série du bac (C, D, A, etc.)
  final String? city;
  final List<String> favoriteUniversities;
  final List<String> interests; // domaines d'intérêt
  final DateTime? lastLoginDate;

  UserProfile({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.series,
    this.city,
    this.favoriteUniversities = const [],
    this.interests = const [],
    this.lastLoginDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      phoneNumber: json['phone_number'],
      name: json['name'],
      series: json['series'],
      city: json['city'],
      favoriteUniversities: List<String>.from(json['favorite_universities'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      lastLoginDate: json['last_login_date'] != null 
          ? DateTime.parse(json['last_login_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'series': series,
      'city': city,
      'favorite_universities': favoriteUniversities,
      'interests': interests,
      'last_login_date': lastLoginDate?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? series,
    String? city,
    List<String>? favoriteUniversities,
    List<String>? interests,
    DateTime? lastLoginDate,
  }) {
    return UserProfile(
      id: id,
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      series: series ?? this.series,
      city: city ?? this.city,
      favoriteUniversities: favoriteUniversities ?? this.favoriteUniversities,
      interests: interests ?? this.interests,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
}
