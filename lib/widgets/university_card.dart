import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/university.dart';
import '../providers/app_provider.dart';

class UniversityCard extends StatelessWidget {
  final University university;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;

  const UniversityCard({
    super.key,
    required this.university,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final distanceText = appProvider.getDistanceToUniversity(university);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'université
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: university.imageUrl != null
                    ? Builder(
                        builder: (context) {
                          print('🖼️ Test CORS - Image pour ${university.name}:');
                          print('   URL: ${university.imageUrl}');
                          
                          // Corriger l'URL pour mobile physique
                          String correctedUrl = university.imageUrl!;
                          if (correctedUrl.contains('127.0.0.1')) {
                            correctedUrl = correctedUrl.replaceAll('127.0.0.1', '192.168.11.121');
                            print('📱 Mobile - URL corrigée: $correctedUrl');
                          }
                          
                          return Image.network(
                            correctedUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                print('✅ Image chargée avec succès: ${university.name}');
                                return child;
                              }
                              print('⏳ Chargement ${university.name}: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Erreur Image.network ${university.name}: $error');
                              print('🔗 URL: ${university.imageUrl}');
                              print('📱 Type d\'erreur: ${error.runtimeType}');
                              
                              return Container(
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.broken_image,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Image indisponible',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      )
                    : const Icon(
                        Icons.school,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom et bouton favori
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          university.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Informations de base
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        university.city,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (distanceText != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $distanceText',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Type d'établissement
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(university.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(university.type),
                          style: TextStyle(
                            color: _getTypeColor(university.type),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Programmes principaux (max 3)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: university.programs
                        .take(3)
                        .map((program) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                program.name,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 11,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  if (university.programs.length > 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${university.programs.length - 3} autre(s) programme(s)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Prix et informations pratiques
                  Row(
                    children: [
                      if (university.minPrice != null) ...[
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        Text(
                          university.priceRange,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Prix non communiqué',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (university.hasScholarships)
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.green[600],
                        ),
                      if (university.hasAccommodation) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.home,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'public':
        return Colors.green;
      case 'private':
        return Colors.blue;
      case 'formation_center':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Privé';
      case 'formation_center':
        return 'Centre de formation';
      default:
        return type;
    }
  }
}
