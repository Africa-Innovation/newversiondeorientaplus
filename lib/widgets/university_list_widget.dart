import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/university_card.dart';
import '../screens/university_detail_screen.dart';

class UniversityListWidget extends StatelessWidget {
  const UniversityListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, List>(
      selector: (context, provider) => provider.universities,
      builder: (context, universities, child) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        
        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshUniversities();
          },
          child: CustomScrollView(
            slivers: [
              // Message d'information sur les résultats
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
                        '${universities.length} résultat(s)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Liste des universités ou message vide
              universities.isEmpty
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
                            const SizedBox(height: 8),
                            Text(
                              'Vérifiez votre connexion internet',
                              style: TextStyle(
                                fontSize: 14,
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
                          final university = universities[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: index == universities.length - 1 ? 100 : 12,
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
                                if (provider.isAuthenticated) {
                                  provider.toggleFavorite(university.id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Connectez-vous pour ajouter aux favoris'),
                                    ),
                                  );
                                }
                              },
                              isFavorite: provider.isFavorite(university.id),
                            ),
                          );
                        },
                        childCount: universities.length,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
