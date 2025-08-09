import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertisement.dart';

class FirebaseAdvertisementService {
  static const String _collection = 'advertisements';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir toutes les publicités actives
  static Future<List<Advertisement>> getAllAdvertisements() async {
    try {
      // Utiliser une requête plus simple pour éviter les problèmes d'index
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('is_active', isEqualTo: true)
          .get();

      final advertisements = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ajouter l'ID du document
        return Advertisement.fromJson(data);
      }).where((ad) => ad.isValid).toList(); // Filtrer les publicités valides

      // Trier localement par priorité puis par date de création
      advertisements.sort((a, b) {
        // D'abord par priorité (descendant)
        int priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        
        // Puis par date de création (descendant)
        return b.startDate.compareTo(a.startDate);
      });

      print('🎯 FirebaseAdvertisementService: ${advertisements.length} publicités récupérées');
      return advertisements;
    } catch (e) {
      print('❌ Erreur lors de la récupération des publicités: $e');
      return [];
    }
  }

  /// Ajouter une nouvelle publicité
  static Future<bool> addAdvertisement(Advertisement advertisement) async {
    try {
      final data = advertisement.toJson();
      data.remove('id'); // Supprimer l'ID car Firestore le génère automatiquement
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).add(data);
      
      print('✅ Publicité ajoutée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la publicité: $e');
      return false;
    }
  }

  /// Mettre à jour une publicité existante
  static Future<bool> updateAdvertisement(Advertisement advertisement) async {
    try {
      final data = advertisement.toJson();
      data.remove('id'); // Supprimer l'ID de la data
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_collection)
          .doc(advertisement.id)
          .update(data);
      
      print('✅ Publicité mise à jour avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la publicité: $e');
      return false;
    }
  }

  /// Supprimer une publicité
  static Future<bool> deleteAdvertisement(String advertisementId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(advertisementId)
          .delete();
      
      print('✅ Publicité supprimée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression de la publicité: $e');
      return false;
    }
  }

  /// Désactiver une publicité (soft delete)
  static Future<bool> deactivateAdvertisement(String advertisementId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(advertisementId)
          .update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Publicité désactivée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la désactivation de la publicité: $e');
      return false;
    }
  }

  /// Obtenir une publicité par ID
  static Future<Advertisement?> getAdvertisementById(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return Advertisement.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la publicité: $e');
      return null;
    }
  }

  /// Obtenir les publicités pour l'admin (toutes, y compris inactives)
  static Future<List<Advertisement>> getAllAdvertisementsForAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .get();

      final advertisements = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Advertisement.fromJson(data);
      }).toList();

      print('🎯 FirebaseAdvertisementService (Admin): ${advertisements.length} publicités récupérées');
      return advertisements;
    } catch (e) {
      print('❌ Erreur lors de la récupération des publicités (Admin): $e');
      return [];
    }
  }

  /// Générer un nouvel ID pour une publicité
  static String generateNewId() {
    return _firestore.collection(_collection).doc().id;
  }
}
