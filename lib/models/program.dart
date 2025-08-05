class Program {
  final String id;
  final String name;
  final String description;
  final List<Specialty> specialties; // Les filières disponibles dans ce programme
  final Map<String, double> priceByLevel; // Prix par niveau (licence, master, doctorat)
  final int durationYears;
  final List<String> admissionRequirements;
  final String? career; // Débouchés professionnels

  Program({
    required this.id,
    required this.name,
    required this.description,
    required this.specialties,
    required this.priceByLevel,
    required this.durationYears,
    required this.admissionRequirements,
    this.career,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      specialties: (json['specialties'] as List?)
          ?.map((s) => Specialty.fromJson(s))
          .toList() ?? [],
      priceByLevel: Map<String, double>.from(json['priceByLevel'] ?? {}),
      durationYears: json['durationYears'] ?? 3,
      admissionRequirements: List<String>.from(json['admissionRequirements'] ?? []),
      career: json['career'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'specialties': specialties.map((s) => s.toJson()).toList(),
      'priceByLevel': priceByLevel,
      'durationYears': durationYears,
      'admissionRequirements': admissionRequirements,
      'career': career,
    };
  }

  // Getters utiles
  List<String> get specialtyNames => specialties.map((s) => s.name).toList();
  
  double? get minPrice {
    if (priceByLevel.isEmpty) return null;
    return priceByLevel.values.reduce((a, b) => a < b ? a : b);
  }
  
  double? get maxPrice {
    if (priceByLevel.isEmpty) return null;
    return priceByLevel.values.reduce((a, b) => a > b ? a : b);
  }

  String get priceRange {
    if (priceByLevel.isEmpty) return 'Prix non communiqué';
    
    final min = minPrice!;
    final max = maxPrice!;
    
    if (min == max) {
      return '${_formatPrice(min)} FCFA/an';
    }
    
    return '${_formatPrice(min)} - ${_formatPrice(max)} FCFA/an';
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    );
  }

  String getLevelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'licence':
        return 'Licence (Bac+3)';
      case 'master':
        return 'Master (Bac+5)';
      case 'doctorat':
        return 'Doctorat (Bac+8)';
      default:
        return level;
    }
  }

  String? getFormattedPrice(String level) {
    final price = priceByLevel[level.toLowerCase()];
    if (price == null) return null;
    return '${_formatPrice(price)} FCFA/an';
  }

  List<String> get availableLevels {
    return priceByLevel.keys.toList()..sort();
  }
}

class Specialty {
  final String id;
  final String name;
  final String description;
  final List<String>? specificRequirements;
  final Map<String, double>? priceByLevel; // Prix spécifiques par niveau pour cette filière

  Specialty({
    required this.id,
    required this.name,
    required this.description,
    this.specificRequirements,
    this.priceByLevel,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      specificRequirements: json['specificRequirements'] != null 
          ? List<String>.from(json['specificRequirements'])
          : null,
      priceByLevel: json['priceByLevel'] != null 
          ? Map<String, double>.from(json['priceByLevel'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'specificRequirements': specificRequirements,
      'priceByLevel': priceByLevel,
    };
  }

  // Méthodes utiles pour les prix de la filière
  String? getFormattedPrice(String level) {
    if (priceByLevel == null) return null;
    final price = priceByLevel![level.toLowerCase()];
    if (price == null) return null;
    return '${_formatPrice(price)} FCFA/an';
  }

  String getLevelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'licence':
        return 'Licence (Bac+3)';
      case 'master':
        return 'Master (Bac+5)';
      case 'doctorat':
        return 'Doctorat (Bac+8)';
      default:
        return level;
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  List<String> get availableLevels {
    if (priceByLevel == null) return [];
    final levels = priceByLevel!.keys.toList();
    levels.sort();
    return levels;
  }
}
