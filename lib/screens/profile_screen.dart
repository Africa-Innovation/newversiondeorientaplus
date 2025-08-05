import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (!provider.isAuthenticated) {
            return _buildLoginPrompt(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Carte de profil utilisateur
                _buildProfileCard(context, provider),
                
                const SizedBox(height: 20),
                
                // Statistiques
                _buildStatsCard(provider),
                
                const SizedBox(height: 20),
                
                // Options du profil
                _buildProfileOptions(context, provider),
                
                const SizedBox(height: 100), // Espace pour le bottom navigation
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Connectez-vous',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Accédez à votre profil et personnalisez votre expérience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Se connecter',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppProvider provider) {
    final user = provider.currentUser!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar et informations de base
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.name?.substring(0, 1).toUpperCase() ?? 
                    (user.phoneNumber.length >= 2 
                        ? user.phoneNumber.substring(user.phoneNumber.length - 2).toUpperCase()
                        : user.phoneNumber.toUpperCase()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user.city != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📍 ${user.city}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showEditProfileDialog(context, provider);
                  },
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            
            if (user.series != null) ...[
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Favoris',
                provider.favoriteUniversities.length.toString(),
                Icons.favorite,
                Colors.red,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildStatItem(
                'Intérêts',
                provider.currentUser?.interests.length.toString() ?? '0',
                Icons.interests,
                Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOptions(BuildContext context, AppProvider provider) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          'Modifier le profil',
          'Changer vos informations personnelles',
          Icons.person,
          () => _showEditProfileDialog(context, provider),
        ),
        _buildOptionTile(
          context,
          'Paramètres de localisation',
          'Gérer vos préférences de localisation',
          Icons.location_on,
          () => provider.requestLocation(),
        ),
        _buildOptionTile(
          context,
          'À propos',
          'Informations sur l\'application',
          Icons.info,
          () => _showAboutDialog(context),
        ),
        _buildOptionTile(
          context,
          'Se déconnecter',
          'Déconnexion de votre compte',
          Icons.logout,
          () => _showLogoutDialog(context, provider),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController(text: provider.currentUser?.name ?? '');
    final cityController = TextEditingController(text: provider.currentUser?.city ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateProfile(
                  name: nameController.text.trim(),
                  city: cityController.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Orienta',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.school,
        color: Theme.of(context).primaryColor,
        size: 48,
      ),
      children: [
        const Text(
          'Votre guide post-bac pour trouver la formation idéale au Burkina Faso.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Développé avec ❤️ pour aider les étudiants burkinabè.',
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
