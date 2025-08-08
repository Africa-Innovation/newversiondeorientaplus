import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class FirebaseUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Sauvegarder le profil utilisateur dans Firebase
  static Future<void> saveUserProfile(UserProfile user) async {
    try {
      print('🔥 Sauvegarde du profil utilisateur dans Firebase...');
      print('   User ID: ${user.id}');
      print('   Favoris: ${user.favoriteUniversities.length}');
      
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
      
      print('✅ Profil utilisateur sauvegardé avec succès');
    } catch (e) {
      print('❌ Erreur sauvegarde profil utilisateur: $e');
      throw Exception('Impossible de sauvegarder le profil: $e');
    }
  }

  /// Charger le profil utilisateur depuis Firebase
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      print('🔥 Chargement du profil utilisateur depuis Firebase...');
      print('   User ID: $userId');
      
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final userProfile = UserProfile.fromJson(doc.data()!);
        print('✅ Profil utilisateur chargé avec succès');
        print('   Nom: ${userProfile.name}');
        print('   Favoris: ${userProfile.favoriteUniversities.length}');
        return userProfile;
      } else {
        print('ℹ️ Aucun profil trouvé pour cet utilisateur');
        return null;
      }
    } catch (e) {
      print('❌ Erreur chargement profil utilisateur: $e');
      return null;
    }
  }

  /// Mettre à jour uniquement les favoris d'un utilisateur
  static Future<void> updateUserFavorites(String userId, List<String> favoriteIds) async {
    try {
      print('🔥 Mise à jour des favoris dans Firebase...');
      print('   User ID: $userId');
      print('   Favoris: $favoriteIds');
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'favorite_universities': favoriteIds,
        'last_login_date': DateTime.now().toIso8601String(),
      });
      
      print('✅ Favoris mis à jour avec succès');
    } catch (e) {
      print('❌ Erreur mise à jour favoris: $e');
      throw Exception('Impossible de mettre à jour les favoris: $e');
    }
  }

  /// Ajouter une université aux favoris
  static Future<void> addFavorite(String userId, String universityId) async {
    try {
      print('🔥 Ajout favori dans Firebase...');
      print('   User ID: $userId');
      print('   University ID: $universityId');
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'favorite_universities': FieldValue.arrayUnion([universityId]),
        'last_login_date': DateTime.now().toIso8601String(),
      });
      
      print('✅ Favori ajouté avec succès');
    } catch (e) {
      print('❌ Erreur ajout favori: $e');
      throw Exception('Impossible d\'ajouter aux favoris: $e');
    }
  }

  /// Supprimer une université des favoris
  static Future<void> removeFavorite(String userId, String universityId) async {
    try {
      print('🔥 Suppression favori dans Firebase...');
      print('   User ID: $userId');
      print('   University ID: $universityId');
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'favorite_universities': FieldValue.arrayRemove([universityId]),
        'last_login_date': DateTime.now().toIso8601String(),
      });
      
      print('✅ Favori supprimé avec succès');
    } catch (e) {
      print('❌ Erreur suppression favori: $e');
      throw Exception('Impossible de supprimer des favoris: $e');
    }
  }

  /// Vérifier si une université est en favoris
  static Future<bool> isFavorite(String userId, String universityId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final favoriteIds = List<String>.from(doc.data()!['favorite_universities'] ?? []);
        return favoriteIds.contains(universityId);
      }
      return false;
    } catch (e) {
      print('❌ Erreur vérification favori: $e');
      return false;
    }
  }

  /// Supprimer un utilisateur de Firebase
  static Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();
      print('✅ Utilisateur supprimé de Firebase');
    } catch (e) {
      print('❌ Erreur suppression utilisateur: $e');
      throw Exception('Impossible de supprimer l\'utilisateur: $e');
    }
  }
}
