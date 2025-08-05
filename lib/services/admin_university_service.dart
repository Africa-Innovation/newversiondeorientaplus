import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/university.dart';
import '../models/program.dart';

class AdminUniversityService {
  static const String _storageKey = 'admin_universities';
  static List<University> _customUniversities = [];

  /// Charge les universités personnalisées depuis le stockage local
  static Future<void> loadCustomUniversities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? universitiesJson = prefs.getString(_storageKey);
      
      if (universitiesJson != null) {
        final List<dynamic> universitiesList = json.decode(universitiesJson);
        _customUniversities = universitiesList
            .map((json) => University.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Erreur lors du chargement des universités: $e');
      _customUniversities = [];
    }
  }

  /// Sauvegarde les universités personnalisées dans le stockage local
  static Future<void> saveCustomUniversities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String universitiesJson = json.encode(
        _customUniversities.map((university) => university.toJson()).toList(),
      );
      await prefs.setString(_storageKey, universitiesJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde des universités: $e');
      throw Exception('Impossible de sauvegarder les universités');
    }
  }

  /// Récupère toutes les universités personnalisées
  static List<University> getCustomUniversities() {
    return List.from(_customUniversities);
  }

  /// Ajoute une nouvelle université
  static Future<void> createUniversity(University university) async {
    // Vérifier si l'ID existe déjà
    if (_customUniversities.any((u) => u.id == university.id)) {
      throw Exception('Une université avec cet ID existe déjà');
    }

    _customUniversities.add(university);
    await saveCustomUniversities();
  }

  /// Met à jour une université existante
  static Future<void> updateUniversity(University updatedUniversity) async {
    final index = _customUniversities.indexWhere(
      (u) => u.id == updatedUniversity.id,
    );

    if (index == -1) {
      throw Exception('Université non trouvée');
    }

    _customUniversities[index] = updatedUniversity;
    await saveCustomUniversities();
  }

  /// Supprime une université
  static Future<void> deleteUniversity(String universityId) async {
    final index = _customUniversities.indexWhere((u) => u.id == universityId);

    if (index == -1) {
      throw Exception('Université non trouvée');
    }

    _customUniversities.removeAt(index);
    await saveCustomUniversities();
  }

  /// Récupère une université par son ID
  static University? getUniversityById(String id) {
    try {
      return _customUniversities.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Génère un nouvel ID unique pour une université
  static String generateNewId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'custom_univ_$timestamp';
  }

  /// Génère un nouvel ID unique pour un programme
  static String generateNewProgramId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'custom_prog_$timestamp';
  }

  /// Génère un nouvel ID unique pour une spécialité
  static String generateNewSpecialtyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'custom_spec_$timestamp';
  }

  /// Valide les données d'une université avant sauvegarde
  static String? validateUniversity(University university) {
    if (university.name.trim().isEmpty) {
      return 'Le nom de l\'université est requis';
    }

    if (university.city.trim().isEmpty) {
      return 'La ville est requise';
    }

    if (university.type.trim().isEmpty) {
      return 'Le type d\'université est requis';
    }

    if (university.programs.isEmpty) {
      return 'Au moins un programme est requis';
    }

    // Valider chaque programme
    for (final program in university.programs) {
      final programError = validateProgram(program);
      if (programError != null) {
        return 'Programme "${program.name}": $programError';
      }
    }

    return null; // Pas d'erreur
  }

  /// Valide les données d'un programme
  static String? validateProgram(Program program) {
    if (program.name.trim().isEmpty) {
      return 'Le nom du programme est requis';
    }

    if (program.description.trim().isEmpty) {
      return 'La description du programme est requise';
    }

    if (program.durationYears <= 0) {
      return 'La durée doit être supérieure à 0';
    }

    if (program.specialties.isEmpty) {
      return 'Au moins une spécialité est requise';
    }

    // Valider chaque spécialité
    for (final specialty in program.specialties) {
      final specialtyError = validateSpecialty(specialty);
      if (specialtyError != null) {
        return 'Spécialité "${specialty.name}": $specialtyError';
      }
    }

    return null;
  }

  /// Valide les données d'une spécialité
  static String? validateSpecialty(Specialty specialty) {
    if (specialty.name.trim().isEmpty) {
      return 'Le nom de la spécialité est requis';
    }

    if (specialty.description.trim().isEmpty) {
      return 'La description de la spécialité est requise';
    }

    if (specialty.priceByLevel?.isEmpty ?? true) {
      return 'Au moins un prix par niveau est requis';
    }

    // Vérifier que tous les prix sont positifs
    for (final entry in specialty.priceByLevel?.entries ?? <MapEntry<String, double>>[]) {
      if (entry.value < 0) {
        return 'Le prix pour ${entry.key} ne peut pas être négatif';
      }
    }

    return null;
  }

  /// Efface toutes les universités personnalisées (pour les tests ou reset)
  static Future<void> clearAllCustomUniversities() async {
    _customUniversities.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
