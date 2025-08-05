import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/university_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_dialog.dart';
import 'university_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.requestLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orienta',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                if (provider.userCity != null) {
                  return Text(
                    '📍 ${provider.userCity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const Text(
                  '📍 Localisation non disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              if (provider.isAuthenticated) {
                return IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      provider.currentUser?.name?.substring(0, 1).toUpperCase() ?? 
                      provider.currentUser?.phoneNumber.substring(0, 1) ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onPressed: () {
                    // Navigation vers profil sera gérée par BottomNavigationBar
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.initialize();
            },
            child: CustomScrollView(
              slivers: [
                // Message de bienvenue
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isAuthenticated 
                              ? 'Bienvenue ${provider.currentUser?.name ?? ""}!'
                              : 'Bienvenue sur Orienta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Votre guide post-bac pour trouver la formation idéale au Burkina Faso',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Barre de recherche et filtre
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            onSearch: (query) {
                              provider.searchUniversities(query);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => FilterDialog(
                                onApplyFilters: (filters) {
                                  provider.setFilters(
                                    city: filters['city'],
                                    type: filters['type'],
                                    domain: filters['domain'],
                                    maxBudget: filters['maxBudget'],
                                    maxDistance: filters['maxDistance'],
                                  );
                                },
                                onClearFilters: () {
                                  provider.clearFilters();
                                },
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.tune,
                            color: Theme.of(context).primaryColor,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Section titre des universités
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          provider.locationPermissionGranted 
                              ? Icons.location_on 
                              : Icons.school,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.locationPermissionGranted 
                              ? 'Universités près de chez vous'
                              : 'Universités disponibles',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${provider.universities.length} résultat(s)',
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
                provider.universities.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
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
                              const SizedBox(height: 8),
                              Text(
                                'Essayez de modifier vos critères de recherche',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final university = provider.universities[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: index == provider.universities.length - 1 ? 100 : 12,
                              ),
                              child: UniversityCard(
                                university: university,
                                userLatitude: provider.userLatitude,
                                userLongitude: provider.userLongitude,
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
                                  if (provider.isAuthenticated) {
                                    provider.toggleFavorite(university.id);
                                  } else {
                                    _showLoginPrompt();
                                  }
                                },
                                isFavorite: provider.isFavorite(university.id),
                              ),
                            );
                          },
                          childCount: provider.universities.length,
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez vous connecter pour ajouter des universités à vos favoris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigation vers l'écran de connexion sera gérée par le BottomNavigationBar
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
