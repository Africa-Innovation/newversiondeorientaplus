import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/advertisement.dart';

class FirebaseAdvertisementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'advertisements';

  /// Méthode d'instance pour compatibilité
  Future<List<Advertisement>> getAdvertisements() async {
    return await getActiveAdvertisements();
  }

  /// Charger toutes les publicités pour l'admin (incluant inactives)
  static Future<List<Advertisement>> getAllAdvertisementsForAdmin() async {
    try {
      debugPrint('🔄 Chargement de toutes les publicités pour admin...');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('priority', descending: true)
          .orderBy('created_at', descending: true)
          .get();

      final List<Advertisement> advertisements = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Advertisement.fromJson(data);
      }).toList();

      debugPrint('🎯 ${advertisements.length} publicités chargées pour admin');
      return advertisements;
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement pour admin: $e');
      rethrow;
    }
  }

  /// Charger uniquement les publicités actives et valides pour l'app
  static Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      debugPrint('🔄 Chargement des publicités actives...');
      
      // Requête simplifiée sans tri pour éviter le problème d'index
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('is_active', isEqualTo: true)
          .get();

      final List<Advertisement> advertisements = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Advertisement.fromJson(data);
      }).toList();

      // Filtrer uniquement les publicités valides (non expirées) et trier en mémoire
      final validAdvertisements = advertisements
          .where((ad) => ad.isValid)
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority)); // Tri par priorité décroissante

      debugPrint('🎯 ${advertisements.length} publicités trouvées, ${validAdvertisements.length} valides');
      return validAdvertisements;
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des publicités actives: $e');
      rethrow;
    }
  }

  /// Ajouter une nouvelle publicité
  static Future<bool> addAdvertisement(Advertisement advertisement) async {
    try {
      debugPrint('📝 Ajout d\'une nouvelle publicité: ${advertisement.title}');
      
      final data = advertisement.toJson();
      data.remove('id'); // Firestore génère l'ID automatiquement
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).add(data);
      
      debugPrint('✅ Publicité ajoutée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de la publicité: $e');
      return false;
    }
  }

  /// Mettre à jour une publicité existante
  static Future<bool> updateAdvertisement(Advertisement advertisement) async {
    try {
      debugPrint('📝 Mise à jour de la publicité: ${advertisement.title}');
      
      final data = advertisement.toJson();
      data.remove('id');
      data.remove('created_at'); // Ne pas modifier la date de création
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(advertisement.id).update(data);
      
      debugPrint('✅ Publicité mise à jour avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de la publicité: $e');
      return false;
    }
  }

  /// Supprimer définitivement une publicité
  static Future<bool> deleteAdvertisement(String advertisementId) async {
    try {
      debugPrint('🗑️ Suppression de la publicité: $advertisementId');
      
      await _firestore.collection(_collection).doc(advertisementId).delete();
      
      debugPrint('✅ Publicité supprimée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la publicité: $e');
      return false;
    }
  }

  /// Désactiver une publicité (soft delete)
  static Future<bool> deactivateAdvertisement(String advertisementId) async {
    try {
      debugPrint('⏸️ Désactivation de la publicité: $advertisementId');
      
      await _firestore.collection(_collection).doc(advertisementId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Publicité désactivée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la désactivation de la publicité: $e');
      return false;
    }
  }

  /// Activer une publicité
  static Future<bool> activateAdvertisement(String advertisementId) async {
    try {
      debugPrint('▶️ Activation de la publicité: $advertisementId');
      
      await _firestore.collection(_collection).doc(advertisementId).update({
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Publicité activée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'activation de la publicité: $e');
      return false;
    }
  }

  /// Charger une publicité spécifique par ID
  static Future<Advertisement?> getAdvertisementById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Advertisement.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la publicité $id: $e');
      return null;
    }
  }

  /// Écouter les changements de publicités en temps réel pour l'admin
  static Stream<List<Advertisement>> watchAllAdvertisements() {
    return _firestore
        .collection(_collection)
        .orderBy('priority', descending: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Advertisement.fromJson(data);
      }).toList();
    });
  }

  /// Écouter les changements de publicités actives en temps réel pour l'app
  static Stream<List<Advertisement>> watchActiveAdvertisements() {
    return _firestore
        .collection(_collection)
        .where('is_active', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) {
      final advertisements = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Advertisement.fromJson(data);
      }).toList();

      // Filtrer uniquement les publicités valides
      return advertisements.where((ad) => ad.isValid).toList();
    });
  }

  /// Compter le nombre de publicités actives
  static Future<int> getActiveAdvertisementsCount() async {
    try {
      final AggregateQuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('is_active', isEqualTo: true)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur lors du comptage des publicités: $e');
      return 0;
    }
  }

  /// Marquer une publicité comme vue (optionnel pour les statistiques)
  static Future<void> markAdvertisementAsViewed(String advertisementId) async {
    try {
      await _firestore
          .collection('advertisement_views')
          .add({
        'advertisement_id': advertisementId,
        'viewed_at': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'enregistrement de la vue: $e');
    }
  }
}
