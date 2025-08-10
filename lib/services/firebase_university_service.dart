import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/university.dart';

class FirebaseUniversityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _universitiesCollection = 'universities';

  /// 🏛️ Sauvegarde une université complète dans Firestore
  static Future<void> saveUniversity(University university) async {
    try {
      // Convertir en Map et s'assurer que tous les champs sont sérialisables
      final universityData = university.toJson();
      
      // Ajouter les timestamps Firebase
      universityData['createdAt'] = FieldValue.serverTimestamp();
      universityData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(_universitiesCollection)
          .doc(university.id)
          .set(universityData, SetOptions(merge: true));
      
      print('✅ Université sauvegardée dans Firestore: ${university.name}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde Firestore: $e');
      throw Exception('Impossible de sauvegarder l\'université dans Firestore: $e');
    }
  }

  /// 📚 Récupère toutes les universités depuis Firestore
  static Future<List<University>> getAllUniversities() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_universitiesCollection)
          .get();

      final List<University> universities = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final university = University.fromJson(data);
          universities.add(university);
        } catch (e) {
          final data = doc.data() as Map<String, dynamic>;
          print('⚠️ Erreur lors du parsing de l\'université ${doc.id}: $e');
          print('🔍 Data problématique: $data');
          print('🔍 Latitude type: ${data['latitude']?.runtimeType}, value: ${data['latitude']}');
          print('🔍 Longitude type: ${data['longitude']?.runtimeType}, value: ${data['longitude']}');
          // Continue avec les autres universités
        }
      }

      // Trier par date de création si disponible, sinon par nom
      universities.sort((a, b) {
        // Pour l'instant, trier par nom en attendant d'avoir les timestamps
        return a.name.compareTo(b.name);
      });

      print('✅ Chargé ${universities.length} universités depuis Firestore');
      return universities;
    } catch (e) {
      print('❌ Erreur lors du chargement Firestore: $e');
      return [];
    }
  }

  /// 🎯 Récupère une université par ID
  static Future<University?> getUniversityById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_universitiesCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return University.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'université $id: $e');
      return null;
    }
  }

  /// 🔄 Met à jour une université
  static Future<void> updateUniversity(University university) async {
    try {
      final universityData = university.toJson();
      universityData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(_universitiesCollection)
          .doc(university.id)
          .update(universityData);
      
      print('✅ Université mise à jour dans Firestore: ${university.name}');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour Firestore: $e');
      throw Exception('Impossible de mettre à jour l\'université dans Firestore: $e');
    }
  }

  /// 🗑️ Supprime une université
  static Future<void> deleteUniversity(String universityId) async {
    try {
      await _firestore
          .collection(_universitiesCollection)
          .doc(universityId)
          .delete();
      
      print('✅ Université supprimée de Firestore: $universityId');
    } catch (e) {
      print('❌ Erreur lors de la suppression Firestore: $e');
      throw Exception('Impossible de supprimer l\'université de Firestore: $e');
    }
  }

  ///  Recherche d'universités par ville
  static Future<List<University>> getUniversitiesByCity(String city) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_universitiesCollection)
          .where('city', isEqualTo: city)
          .get();

      final List<University> universities = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          universities.add(University.fromJson(data));
        } catch (e) {
          print('⚠️ Erreur parsing université ${doc.id}: $e');
        }
      }

      return universities;
    } catch (e) {
      print('❌ Erreur recherche par ville: $e');
      return [];
    }
  }

  /// 🏷️ Recherche d'universités par type
  static Future<List<University>> getUniversitiesByType(String type) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_universitiesCollection)
          .where('type', isEqualTo: type)
          .get();

      final List<University> universities = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          universities.add(University.fromJson(data));
        } catch (e) {
          print('⚠️ Erreur parsing université ${doc.id}: $e');
        }
      }

      return universities;
    } catch (e) {
      print('❌ Erreur recherche par type: $e');
      return [];
    }
  }

  /// 📊 Écouter les changements en temps réel
  static Stream<List<University>> getUniversitiesStream() {
    return _firestore
        .collection(_universitiesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final universities = <University>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          universities.add(University.fromJson(data));
        } catch (e) {
          print('⚠️ Erreur parsing université ${doc.id}: $e');
        }
      }
      return universities;
    });
  }

  /// 🔧 Tester la connexion Firestore
  static Future<bool> testFirestoreConnection() async {
    try {
      await _firestore
          .collection('test')
          .doc('connection_test')
          .set({'timestamp': FieldValue.serverTimestamp()});
      
      await _firestore
          .collection('test')
          .doc('connection_test')
          .delete();
      
      print('✅ Connexion Firestore réussie');
      return true;
    } catch (e) {
      print('❌ Test connexion Firestore échoué: $e');
      return false;
    }
  }

  /// 📈 Obtenir des statistiques
  static Future<Map<String, int>> getUniversityStats() async {
    try {
      final snapshot = await _firestore
          .collection(_universitiesCollection)
          .get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'public': 0,
        'private': 0,
        'formation_center': 0,
      };

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final type = data['type'] as String? ?? 'unknown';
          stats[type] = (stats[type] ?? 0) + 1;
        } catch (e) {
          print('⚠️ Erreur lors du calcul des stats pour ${doc.id}: $e');
        }
      }

      return stats;
    } catch (e) {
      print('❌ Erreur lors du calcul des statistiques: $e');
      return {'total': 0};
    }
  }

  /// 🔄 Synchronisation batch (pour migration ou backup)
  static Future<void> batchSaveUniversities(List<University> universities) async {
    try {
      final batch = _firestore.batch();
      
      for (var university in universities) {
        final docRef = _firestore
            .collection(_universitiesCollection)
            .doc(university.id);
        
        final data = university.toJson();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();
        
        batch.set(docRef, data, SetOptions(merge: true));
      }
      
      await batch.commit();
      print('✅ Sauvegarde batch de ${universities.length} universités terminée');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde batch: $e');
      throw Exception('Impossible de sauvegarder les universités en batch: $e');
    }
  }
}
