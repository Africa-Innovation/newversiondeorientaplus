import 'package:flutter/foundation.dart';
import '../models/advertisement.dart';
import '../services/firebase_advertisement_service.dart';

class AdminAdvertisementProvider with ChangeNotifier {
  List<Advertisement> _advertisements = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Advertisement> get advertisements => _advertisements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charger toutes les publicités pour l'admin
  Future<void> loadAdvertisements() async {
    _setLoading(true);
    _clearError();
    
    try {
      _advertisements = await FirebaseAdvertisementService.getAllAdvertisementsForAdmin();
      debugPrint('🎯 AdminAdvertisementProvider: ${_advertisements.length} publicités chargées');
    } catch (e) {
      _setError('Erreur lors du chargement des publicités: $e');
      debugPrint('❌ Erreur chargement publicités: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Ajouter une nouvelle publicité
  Future<bool> addAdvertisement(Advertisement advertisement) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await FirebaseAdvertisementService.addAdvertisement(advertisement);
      
      if (success) {
        // Recharger la liste pour avoir les dernières données
        await loadAdvertisements();
        debugPrint('✅ Publicité ajoutée avec succès');
        return true;
      } else {
        _setError('Erreur lors de l\'ajout de la publicité');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de l\'ajout: $e');
      debugPrint('❌ Erreur ajout publicité: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mettre à jour une publicité existante
  Future<bool> updateAdvertisement(Advertisement advertisement) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await FirebaseAdvertisementService.updateAdvertisement(advertisement);
      
      if (success) {
        // Mettre à jour la liste locale
        final index = _advertisements.indexWhere((ad) => ad.id == advertisement.id);
        if (index != -1) {
          _advertisements[index] = advertisement;
          notifyListeners();
        }
        debugPrint('✅ Publicité mise à jour avec succès');
        return true;
      } else {
        _setError('Erreur lors de la mise à jour de la publicité');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      debugPrint('❌ Erreur mise à jour publicité: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprimer une publicité
  Future<bool> deleteAdvertisement(String advertisementId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await FirebaseAdvertisementService.deleteAdvertisement(advertisementId);
      
      if (success) {
        // Supprimer de la liste locale
        _advertisements.removeWhere((ad) => ad.id == advertisementId);
        notifyListeners();
        debugPrint('✅ Publicité supprimée avec succès');
        return true;
      } else {
        _setError('Erreur lors de la suppression de la publicité');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      debugPrint('❌ Erreur suppression publicité: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Désactiver une publicité (soft delete)
  Future<bool> deactivateAdvertisement(String advertisementId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await FirebaseAdvertisementService.deactivateAdvertisement(advertisementId);
      
      if (success) {
        // Mettre à jour la liste locale
        final index = _advertisements.indexWhere((ad) => ad.id == advertisementId);
        if (index != -1) {
          _advertisements[index] = _advertisements[index].copyWith(isActive: false);
          notifyListeners();
        }
        debugPrint('✅ Publicité désactivée avec succès');
        return true;
      } else {
        _setError('Erreur lors de la désactivation de la publicité');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la désactivation: $e');
      debugPrint('❌ Erreur désactivation publicité: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtenir une publicité par ID
  Advertisement? getAdvertisementById(String id) {
    try {
      return _advertisements.firstWhere((ad) => ad.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filtrer les publicités actives
  List<Advertisement> get activeAdvertisements {
    return _advertisements.where((ad) => ad.isActive && ad.isValid).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Filtrer les publicités inactives
  List<Advertisement> get inactiveAdvertisements {
    return _advertisements.where((ad) => !ad.isActive).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  }

  /// Filtrer les publicités expirées
  List<Advertisement> get expiredAdvertisements {
    final now = DateTime.now();
    return _advertisements.where((ad) => ad.isActive && now.isAfter(ad.endDate)).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
