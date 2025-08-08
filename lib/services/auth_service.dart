import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/user_profile.dart';
import 'firebase_user_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _verificationKey = 'verification_key';
  
  // Configuration de l'API Ikoddi
  static const String _baseUrl = 'https://api.ikoddi.com/api/v1';
  static const String _groupId = '10275657';
  static const String _providerId = 'cm3m40nas0rces601ty9i66tz';
  static const String _apiKey = 'sPdb1lqIoWJzqhlwBrmGxqQ0qmEdR1BJ';

  // Envoyer un OTP via l'API Ikoddi
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Formater le numéro de téléphone (s'assurer qu'il commence par +226)
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Si le numéro commence par 226, ajouter le +
        if (phoneNumber.startsWith('226')) {
          formattedPhone = '+$phoneNumber';
        } else {
          // Sinon, ajouter +226
          formattedPhone = '+226$phoneNumber';
        }
      }
      
      final url = '$_baseUrl/groups/$_groupId/otp/$_providerId/sms/$formattedPhone';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Réponse envoi OTP: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Stocker la clé de vérification
        if (responseData['otpToken'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_verificationKey, jsonEncode({
            'phone': formattedPhone,
            'verificationKey': responseData['otpToken'], // Utiliser otpToken comme verificationKey
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
          print('Clé de vérification stockée pour: $formattedPhone');
        } else {
          print('Aucun otpToken reçu dans la réponse');
        }
        
        return true;
      } else {
        print('Erreur API envoi OTP: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erreur envoi OTP: $e');
      return false;
    }
  }

  // Vérifier l'OTP via l'API Ikoddi
  Future<UserProfile?> verifyOTP(String phoneNumber, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationData = prefs.getString(_verificationKey);
      
      print('Données de vérification trouvées: $verificationData');
      
      if (verificationData == null) {
        print('Aucune clé de vérification trouvée');
        return null;
      }
      
      final verificationInfo = jsonDecode(verificationData);
      final verificationKey = verificationInfo['verificationKey'];
      final timestamp = verificationInfo['timestamp'];
      
      // Vérifier l'expiration (10 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = (now - timestamp) > (10 * 60 * 1000);
      
      if (isExpired) {
        print('Clé de vérification expirée');
        await prefs.remove(_verificationKey);
        return null;
      }
      
      // Formater le numéro de téléphone
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('226')) {
          formattedPhone = '+$phoneNumber';
        } else {
          formattedPhone = '+226$phoneNumber';
        }
      }
      
      // Appel API pour vérifier l'OTP
      final url = '$_baseUrl/groups/$_groupId/otp/$_providerId/verify';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'verificationKey': verificationKey,
          'otp': otp,
          'identity': formattedPhone,
        }),
      );
      
      print('Réponse vérification OTP: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Vérifier aussi le status dans la réponse JSON
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 0) { // status 0 = succès selon l'API Ikoddi
          // OTP valide, créer ou récupérer l'utilisateur
          UserProfile user;
          final existingUserData = await _getUserByPhone(formattedPhone);
          
          if (existingUserData != null) {
            user = existingUserData;
          } else {
            // Créer un nouveau utilisateur
            user = UserProfile(
              id: _generateUserId(),
              phoneNumber: formattedPhone,
              lastLoginDate: DateTime.now(),
            );
          }
          
          // Mettre à jour la date de dernière connexion
          user = user.copyWith(lastLoginDate: DateTime.now());
          
          // Sauvegarder l'utilisateur
          await _saveUser(user);
          
          // Nettoyer la clé de vérification
          await prefs.remove(_verificationKey);
          
          print('Connexion réussie pour: $formattedPhone');
          return user;
        } else {
          print('Erreur dans la réponse API: ${responseData['message'] ?? 'Status non-zéro'}');
          return null;
        }
      } else {
        print('Erreur API vérification OTP: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur vérification OTP: $e');
      return null;
    }
  }

  // Obtenir l'utilisateur actuel
  Future<UserProfile?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      
      if (userData != null) {
        final localUser = UserProfile.fromJson(jsonDecode(userData));
        
        // 🔥 NOUVEAU: Essayer de récupérer depuis Firebase pour synchroniser
        try {
          final firebaseUser = await FirebaseUserService.getUserProfile(localUser.id);
          if (firebaseUser != null) {
            // Utiliser les données Firebase si disponibles
            await prefs.setString(_userKey, jsonEncode(firebaseUser.toJson()));
            return firebaseUser;
          }
        } catch (e) {
          print('⚠️ Impossible de synchroniser depuis Firebase: $e');
        }
        
        return localUser;
      }
      return null;
    } catch (e) {
      print('Erreur récupération utilisateur: $e');
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(UserProfile user) async {
    await _saveUser(user);
  }

  // 🔥 NOUVEAU: Mettre à jour uniquement les favoris
  Future<void> updateUserFavorites(String userId, List<String> favoriteIds) async {
    try {
      // Mettre à jour Firebase directement
      await FirebaseUserService.updateUserFavorites(userId, favoriteIds);
      
      // Mettre à jour aussi localement
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser.id == userId) {
        final updatedUser = UserProfile(
          id: currentUser.id,
          name: currentUser.name,
          phoneNumber: currentUser.phoneNumber,
          series: currentUser.series,
          city: currentUser.city,
          favoriteUniversities: favoriteIds,
          interests: currentUser.interests,
          lastLoginDate: DateTime.now(),
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      }
      
      print('✅ Favoris mis à jour avec succès');
    } catch (e) {
      print('❌ Erreur mise à jour favoris: $e');
      throw e;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_verificationKey);
  }

  // Méthodes privées
  Future<void> _saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    
    // 🔥 NOUVEAU: Sauvegarder aussi dans Firebase
    try {
      await FirebaseUserService.saveUserProfile(user);
      print('✅ Profil utilisateur synchronisé avec Firebase');
    } catch (e) {
      print('⚠️ Impossible de synchroniser avec Firebase: $e');
      // Continue avec SharedPreferences seulement en cas d'erreur Firebase
    }
  }

  Future<UserProfile?> _getUserByPhone(String phoneNumber) async {
    // 🔥 NOUVEAU: Chercher d'abord dans Firebase
    try {
      UserProfile? firebaseUser = await FirebaseUserService.getUserByPhone(phoneNumber);
      if (firebaseUser != null) {
        print('✅ Utilisateur existant trouvé dans Firebase');
        return firebaseUser;
      }
    } catch (e) {
      print('⚠️ Impossible de chercher dans Firebase: $e');
    }
    
    // Fallback: chercher localement
    final currentUser = await getCurrentUser();
    if (currentUser?.phoneNumber == phoneNumber) {
      return currentUser;
    }
    return null;
  }

  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'user_${timestamp}_$random';
  }
}
