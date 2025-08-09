class Advertisement {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String? targetUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int priority; // Plus le nombre est élevé, plus la priorité est haute
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Advertisement({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.targetUrl,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.priority = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Vérifie si la publicité est valide pour l'affichage
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }

  // Factory pour créer depuis JSON
  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetUrl: json['target_url'],
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      isActive: json['is_active'] ?? true,
      priority: json['priority'] ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  // Helper pour parser les dates depuis Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    
    // Gestion des Timestamp Firestore
    if (value is Map && value.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    
    return DateTime.now();
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'description': description,
      'target_url': targetUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'priority': priority,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  Advertisement copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? description,
    String? targetUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Advertisement(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      targetUrl: targetUrl ?? this.targetUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Advertisement(id: $id, title: $title, isValid: $isValid, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Advertisement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
