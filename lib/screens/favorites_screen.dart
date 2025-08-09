import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/university_card.dart';
import '../models/university.dart';
import 'university_detail_screen.dart';
import 'auth_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // Variables locales pour éviter les Consumer
  List<University> _favoriteUniversities = [];
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      // Charger les données une seule fois
      await provider.initialize();
      
      _updateLocalState(provider);
      _isInitialized = true;
    }
  }

  void _updateLocalState(AppProvider provider) {
    if (mounted) {
      setState(() {
        _favoriteUniversities = provider.favoriteUniversities;
        _isAuthenticated = provider.isAuthenticated;
        _isLoading = provider.isLoading;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mettre à jour l'état local quand on revient sur cette page
    if (_isInitialized) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _updateLocalState(provider);
    }
  }

  Future<void> _refreshFavorites() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.initialize();
    _updateLocalState(provider);
  }

  void _toggleFavorite(String universityId) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.toggleFavorite(universityId);
    _updateLocalState(provider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Favoris',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_favoriteUniversities.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteUniversities.length,
        itemBuilder: (context, index) {
          final university = _favoriteUniversities[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _favoriteUniversities.length - 1 ? 100 : 12,
            ),
            child: UniversityCard(
              university: university,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UniversityDetailScreen(
                      university: university,
                    ),
                  ),
                );
              },
              onFavoriteToggle: () {
                _toggleFavorite(university.id);
              },
              isFavorite: true, // Toujours vrai dans cette liste
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
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Connectez-vous pour voir vos favoris',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Sauvegardez vos universités préférées pour les retrouver facilement',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune université favorite',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Explorez les universités et ajoutez vos préférées à cette liste',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Le BottomNavigationBar gèrera la navigation vers l'accueil
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explorer les universités'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
