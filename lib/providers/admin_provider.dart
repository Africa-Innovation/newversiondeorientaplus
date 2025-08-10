import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/university.dart';
import '../services/firebase_university_service.dart';

class AdminProvider with ChangeNotifier {
  // État des universités dans l'administration
  List<University> _adminUniversities = [];
  bool _isLoading = false;
  String? _error;
  int _userCount = 0;

  // Getters
  List<University> get adminUniversities => _adminUniversities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get userCount => _userCount;

  /// Charger toutes les universités depuis Firebase pour l'administration
  Future<void> loadAdminUniversities() async {
    _setLoading(true);
    _error = null;
    
    try {
      print('🔥 AdminProvider: Chargement des universités depuis Firebase...');
      
      // Charger UNIQUEMENT depuis Firebase
      List<University> firebaseUniversities = await FirebaseUniversityService.getAllUniversities();
      print('✅ AdminProvider: ${firebaseUniversities.length} universités chargées depuis Firebase');
      
      _adminUniversities = firebaseUniversities;
      print('✅ AdminProvider: ${_adminUniversities.length} universités totales chargées');

      // Charger aussi le nombre d'utilisateurs
      await _loadUserCount();
      
    } catch (e) {
      _error = 'Erreur lors du chargement des universités: $e';
      print('❌ AdminProvider: $_error');
      debugPrint(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Charger le nombre d'utilisateurs depuis Firebase
  Future<void> _loadUserCount() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      _userCount = usersSnapshot.docs.length;
      print('✅ AdminProvider: ${_userCount} utilisateurs trouvés');
    } catch (e) {
      print('❌ AdminProvider: Erreur lors du chargement des utilisateurs: $e');
      _userCount = 0;
    }
  }

  /// Ajouter une nouvelle université
  Future<bool> addUniversity(University university) async {
    _setLoading(true);
    _error = null;
    
    try {
      print('🔥 AdminProvider: Ajout université ${university.name}...');
      
      // Sauvegarder UNIQUEMENT dans Firebase
      await FirebaseUniversityService.saveUniversity(university);
      
      // Ajouter à la liste locale immédiatement pour l'UI
      _adminUniversities.add(university);
      notifyListeners();
      
      print('✅ AdminProvider: Université ajoutée avec succès');
      return true;
      
    } catch (e) {
      _error = 'Erreur lors de l\'ajout: $e';
      print('❌ AdminProvider: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mettre à jour une université
  Future<bool> updateUniversity(University university) async {
    _setLoading(true);
    _error = null;
    
    try {
      print('🔥 AdminProvider: Mise à jour université ${university.name}...');
      
      // Mettre à jour dans Firebase
      await FirebaseUniversityService.updateUniversity(university);
      
      // Mettre à jour dans la liste locale
      int index = _adminUniversities.indexWhere((u) => u.id == university.id);
      if (index != -1) {
        _adminUniversities[index] = university;
        notifyListeners();
      }
      
      print('✅ AdminProvider: Université mise à jour avec succès');
      return true;
      
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      print('❌ AdminProvider: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprimer une université
  Future<bool> deleteUniversity(String universityId) async {
    _setLoading(true);
    _error = null;
    
    try {
      print('🔥 AdminProvider: Suppression université $universityId...');
      
      // Supprimer de Firebase
      await FirebaseUniversityService.deleteUniversity(universityId);
      
      // Supprimer de la liste locale
      _adminUniversities.removeWhere((u) => u.id == universityId);
      notifyListeners();
      
      print('✅ AdminProvider: Université supprimée avec succès');
      return true;
      
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      print('❌ AdminProvider: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Recharger les universités
  Future<void> refreshUniversities() async {
    await loadAdminUniversities();
  }

  /// Rechercher une université par ID
  University? findUniversityById(String id) {
    try {
      return _adminUniversities.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
