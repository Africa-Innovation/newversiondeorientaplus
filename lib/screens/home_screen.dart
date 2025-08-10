import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/home_cache.dart';
import '../models/university.dart';
import '../widgets/university_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/welcome_banner_with_ads.dart';
import 'university_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // Variables locales pour éviter les Consumer
  List<University> _universities = [];
  String? _userCity;
  bool _hasLocation = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  Set<String> _favoriteIds = {}; // État local des favoris

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      // Les données se chargent automatiquement via le constructeur AppProvider
      // Plus besoin d'appeler provider.initialize()
      
      _updateLocalState(provider);
      _isInitialized = true;
      
      // 🔥 NOUVEAU: S'assurer que le loading s'arrête même sans localisation
      if (mounted) {
        setState(() {
          _isLoading = false; // Forcer l'arrêt du loading après l'initialisation
        });
      }
    }
  }

  void _updateLocalState(AppProvider provider) {
    setState(() {
      _universities = provider.universities;
      _userCity = provider.userCity;
      _hasLocation = provider.hasUserLocation;
      
      // 🔄 MODIFIÉ: Ne pas dépendre uniquement du provider.isLoading
      // Si on a des universités, on peut arrêter le loading même sans localisation
      _isLoading = provider.isLoading && _universities.isEmpty;
      
      // Mettre à jour les favoris localement
      _favoriteIds = provider.favoriteUniversities.map((u) => u.id).toSet();
    });
    
    // Mettre à jour le cache
    HomeCache.updateUniversities(_universities);
    HomeCache.updateLocation(_userCity, _hasLocation);
  }

  Future<void> _requestLocationPermission() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    bool locationObtained = await provider.requestUserLocation();
    
    if (mounted) {
      _updateLocalState(provider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationObtained ? 'Localisation activée' : 'Impossible d\'obtenir la localisation'),
          backgroundColor: locationObtained ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.refreshUniversities();
    if (mounted) {
      _updateLocalState(provider);
    }
  }

  void _toggleFavorite(String universityId) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    if (!provider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour ajouter aux favoris'),
        ),
      );
      return;
    }

    // Optimistic update - mettre à jour l'UI immédiatement
    setState(() {
      if (_favoriteIds.contains(universityId)) {
        _favoriteIds.remove(universityId);
      } else {
        _favoriteIds.add(universityId);
      }
    });

    // Ensuite faire l'appel API
    await provider.toggleFavorite(universityId);
    
    // Synchroniser avec l'état du provider au cas où il y aurait une erreur
    if (mounted) {
      _updateLocalState(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Synchroniser uniquement si nécessaire et éviter les boucles
        if (_isInitialized && mounted) {
          // Synchronisation simple sans setState pour éviter les boucles
          _universities = provider.universities;
          _userCity = provider.userCity;
          _hasLocation = provider.hasUserLocation;
          _isLoading = provider.isLoading && _universities.isEmpty;
          _favoriteIds = provider.favoriteUniversities.map((u) => u.id).toSet();
        }
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OrientaPlus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userCity ?? 'Localisation non disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _hasLocation ? Icons.location_on : Icons.location_off,
                  color: _hasLocation ? Colors.green : Colors.grey,
                ),
                onPressed: _requestLocationPermission,
                tooltip: _hasLocation ? 'Localisation activée' : 'Activer la localisation',
              ),
            ],
          ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  // En-tête de bienvenue avec carrousel publicitaire
                  SliverToBoxAdapter(
                    child: WelcomeBannerWithAds(
                      onAdTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Publicité cliquée !'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Barre de recherche
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomSearchBar(
                        onSearch: (query) {
                          final provider = Provider.of<AppProvider>(context, listen: false);
                          provider.searchUniversities(query);
                          _updateLocalState(provider);
                        },
                        initialValue: Provider.of<AppProvider>(context, listen: false).searchQuery,
                      ),
                    ),
                  ),
                  
                  // Info localisation
                  if (_userCity != null)
                  if (_hasLocation || _userCity != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasLocation ? Icons.location_on : Icons.location_off,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Votre position: $_userCity',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Affichage si pas de localisation
                  if (!_hasLocation && _userCity == null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_disabled,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Localisation désactivée - Les distances ne seront pas affichées',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _requestLocationPermission,
                              child: Text(
                                'Activer',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Nombre de résultats
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_universities.length} résultat(s)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Liste des universités
                  _universities.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune université trouvée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final university = _universities[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: index == _universities.length - 1 ? 100 : 12,
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
                                  isFavorite: _favoriteIds.contains(university.id),
                                ),
                              );
                            },
                            childCount: _universities.length,
                          ),
                        ),
                ],
              ),
            ),
        );
      },
    );
  }
}
