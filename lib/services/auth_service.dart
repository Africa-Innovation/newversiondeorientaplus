import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user_profile.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _otpKey = 'pending_otp';

  // Simuler l'envoi d'OTP (en production, utiliser Firebase Auth ou un service SMS)
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Générer un OTP aléatoire
      final random = Random();
      final otp = (1000 + random.nextInt(9000)).toString();
      
      // Stocker l'OTP temporairement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_otpKey, jsonEncode({
        'phone': phoneNumber,
        'otp': otp,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
      
      // En mode développement, afficher l'OTP dans la console
      print('OTP pour $phoneNumber: $otp');
      
      return true;
    } catch (e) {
      print('Erreur envoi OTP: $e');
      return false;
    }
  }

  // Vérifier l'OTP et créer/connecter l'utilisateur
  Future<UserProfile?> verifyOTP(String phoneNumber, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final otpData = prefs.getString(_otpKey);
      
      if (otpData == null) return null;
      
      final otpInfo = jsonDecode(otpData);
      final storedPhone = otpInfo['phone'];
      final storedOtp = otpInfo['otp'];
      final timestamp = otpInfo['timestamp'];
      
      // Vérifier la validité de l'OTP (5 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = (now - timestamp) > (5 * 60 * 1000);
      
      if (storedPhone != phoneNumber || storedOtp != otp || isExpired) {
        return null;
      }
      
      // OTP valide, créer ou récupérer l'utilisateur
      UserProfile user;
      final existingUserData = await _getUserByPhone(phoneNumber);
      
      if (existingUserData != null) {
        user = existingUserData;
      } else {
        // Créer un nouveau utilisateur
        user = UserProfile(
          id: _generateUserId(),
          phoneNumber: phoneNumber,
          lastLoginDate: DateTime.now(),
        );
      }
      
      // Mettre à jour la date de dernière connexion
      user = user.copyWith(lastLoginDate: DateTime.now());
      
      // Sauvegarder l'utilisateur
      await _saveUser(user);
      
      // Nettoyer l'OTP
      await prefs.remove(_otpKey);
      
      return user;
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
        return UserProfile.fromJson(jsonDecode(userData));
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

  // Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Méthodes privées
  Future<void> _saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserProfile?> _getUserByPhone(String phoneNumber) async {
    // En production, ceci ferait appel à une base de données
    // Pour le MVP, on vérifie juste s'il y a un utilisateur local
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
