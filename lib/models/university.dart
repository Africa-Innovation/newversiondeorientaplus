import 'dart:math' as math;
import 'program.dart';

class University {
  final String id;
  final String name;
  final String city;
  final String type; // public, private, formation_center
  final List<Program> programs; // Programmes avec leurs filières
  final double? tuitionFee; // Prix de base (optionnel)
  final String? website;
  final String? contact;
  final String? email;
  final String? address;
  final String? imageUrl;
  final String? description;
  final List<String>? generalAdmissionRequirements;
  final bool hasScholarships;
  final bool hasAccommodation;
  final double latitude;
  final double longitude;

  University({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.programs,
    required this.latitude,
    required this.longitude,
    this.tuitionFee,
    this.website,
    this.contact,
    this.email,
    this.address,
    this.imageUrl,
    this.description,
    this.generalAdmissionRequirements,
    this.hasScholarships = false,
    this.hasAccommodation = false,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      type: json['type'],
      programs:
          (json['programs'] as List?)
              ?.map((s) => Program.fromJson(s))
              .toList() ??
          [],
      tuitionFee: json['tuition_fee']?.toDouble(),
      website: json['website'],
      contact: json['contact'],
      email: json['email'],
      address: json['address'],
      imageUrl: json['image_url'],
      description: json['description'],
      generalAdmissionRequirements:
          json['general_admission_requirements'] != null
          ? List<String>.from(json['general_admission_requirements'])
          : null,
      hasScholarships: json['has_scholarships'] ?? false,
      hasAccommodation: json['has_accommodation'] ?? false,
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'type': type,
      'programs': programs.map((s) => s.toJson()).toList(),
      'tuition_fee': tuitionFee,
      'website': website,
      'contact': contact,
      'email': email,
      'address': address,
      'image_url': imageUrl,
      'description': description,
      'general_admission_requirements': generalAdmissionRequirements,
      'has_scholarships': hasScholarships,
      'has_accommodation': hasAccommodation,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Calculer la distance avec la position actuelle
  double distanceFrom(double userLat, double userLng) {
    return _calculateDistance(userLat, userLng, latitude, longitude);
  }

  // Obtenir toutes les filières sous forme de liste de noms
  List<String> get specialtyNames {
    return programs.expand((p) => p.specialtyNames).toList();
  }

  // Obtenir tous les domaines disponibles (noms des programmes)
  List<String> get domains {
    return programs.map((p) => p.name).toSet().toList();
  }

  // Obtenir le prix minimum de l'université
  double? get minPrice {
    final allPrices = <double>[];

    // Ajouter le prix de base si disponible
    if (tuitionFee != null) allPrices.add(tuitionFee!);

    // Ajouter tous les prix des programmes
    for (final program in programs) {
      final programMin = program.minPrice;
      if (programMin != null) allPrices.add(programMin);
    }

    if (allPrices.isEmpty) return null;
    return allPrices.reduce((a, b) => a < b ? a : b);
  }

  // Obtenir le prix maximum de l'université
  double? get maxPrice {
    final allPrices = <double>[];

    // Ajouter le prix de base si disponible
    if (tuitionFee != null) allPrices.add(tuitionFee!);

    // Ajouter tous les prix des programmes
    for (final program in programs) {
      final programMax = program.maxPrice;
      if (programMax != null) allPrices.add(programMax);
    }

    if (allPrices.isEmpty) return null;
    return allPrices.reduce((a, b) => a > b ? a : b);
  }

  // Obtenir une description des prix
  String get priceRange {
    if (minPrice == null) return 'Prix non communiqué';
    if (minPrice == maxPrice) {
      return '${minPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA/an';
    }
    return 'À partir de ${minPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA/an';
  }

  // Vérifier si une filière est disponible
  bool hasSpecialty(String specialtyName) {
    return programs.any(
      (p) =>
          p.name.toLowerCase().contains(specialtyName.toLowerCase()) ||
          p.specialtyNames.any(
            (s) => s.toLowerCase().contains(specialtyName.toLowerCase()),
          ),
    );
  }

  // Obtenir un programme par nom
  Program? getProgram(String programName) {
    try {
      return programs.firstWhere(
        (p) => p.name.toLowerCase() == programName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Formule de Haversine simplifiée pour calculer la distance en km
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}
