import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/university.dart';
import '../providers/app_provider.dart';
import 'program_detail_screen.dart';

class UniversityDetailScreen extends StatelessWidget {
  final University university;

  const UniversityDetailScreen({
    super.key,
    required this.university,
  });

  /// Corrige l'URL de l'image pour la plateforme actuelle
  String? _getCorrectImageUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    
    // Debug: toujours afficher la plateforme
    print('🔧 Detail Correction URL - Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('   URL entrée: $imageUrl');
    
    // Sur mobile physique, remplacer localhost par l'IP réelle
    if (!kIsWeb) {
      String correctedUrl = imageUrl;
      
      if (correctedUrl.contains('127.0.0.1')) {
        correctedUrl = correctedUrl.replaceAll('127.0.0.1', '192.168.11.101');
        print('   ✅ Remplacement 127.0.0.1 → 192.168.11.101');
      }
      
      if (correctedUrl.contains('192.168.11.121')) {
        correctedUrl = correctedUrl.replaceAll('192.168.11.121', '192.168.11.101');
        print('   ✅ Remplacement 192.168.11.121 → 192.168.11.101');
      }
      
      if (correctedUrl.contains('localhost')) {
        correctedUrl = correctedUrl.replaceAll('localhost', '192.168.11.101');
        print('   ✅ Remplacement localhost → 192.168.11.101');
      }
      
      print('   URL corrigée: $correctedUrl');
      return correctedUrl;
    }
    
    print('   ℹ️ Web - pas de correction nécessaire');
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: university.imageUrl != null
                  ? Builder(
                      builder: (context) {
                        // Corriger l'URL pour la plateforme actuelle
                        final correctedUrl = _getCorrectImageUrl(university.imageUrl);
                        
                        print('🖼️ Detail Image URL pour ${university.name}:');
                        print('   Original: ${university.imageUrl}');
                        print('   Corrigée: $correctedUrl');
                        
                        return CachedNetworkImage(
                          imageUrl: correctedUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('❌ Erreur chargement image detail ${university.name}: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image indisponible',
                                    style: TextStyle(
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
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.school,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
            ),
            actions: [
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final isFavorite = provider.isFavorite(university.id);
                  return IconButton(
                    onPressed: () {
                      if (provider.isAuthenticated) {
                        provider.toggleFavorite(university.id);
                      } else {
                        _showLoginPrompt(context);
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[700],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et badges
                  _buildHeader(context),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  if (university.description != null) ...[
                    _buildSection(
                      'À propos',
                      Text(
                        university.description!,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Filières disponibles
                  _buildSection(
                    'Filières et Programmes disponibles',
                    _buildSpecialtiesAndPrograms(),
                  ),
                  
                  const SizedBox(height: 20),

                  // Conditions d'admission générales
                  if (university.generalAdmissionRequirements != null) ...[
                    _buildSection(
                      'Conditions d\'admission générales',
                      _buildAdmissionRequirements(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Informations pratiques
                  _buildSection(
                    'Informations pratiques',
                    _buildPracticalInfo(context),
                  ),

                  const SizedBox(height: 20),

                  // Informations de contact
                  _buildSection(
                    'Contact',
                    _buildContactInfo(),
                  ),

                  const SizedBox(height: 100), // Espace pour le bottom navigation
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          university.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Badges et informations
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge(
              _getTypeLabel(university.type),
              _getTypeColor(university.type),
            ),
            _buildBadge(
              university.city,
              Colors.blue,
              icon: Icons.location_on,
            ),
            _buildBadge(
              'Programmes variés',
              Colors.orange,
              icon: Icons.school,
            ),
            if (university.hasScholarships)
              _buildBadge(
                'Bourses disponibles',
                Colors.green,
                icon: Icons.school,
              ),
            if (university.hasAccommodation)
              _buildBadge(
                'Logement',
                Colors.purple,
                icon: Icons.home,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSpecialtiesAndPrograms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: university.programs.map((program) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: ThemeData().copyWith(dividerColor: Colors.transparent),
            child: Builder(
              builder: (context) => ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                title: Text(
                  program.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durée: ${program.durationYears} ans',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      program.priceRange,
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                children: [
                  if (program.description.isNotEmpty) ...[
                    Text(
                      program.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Niveaux et prix
                  if (program.priceByLevel.isNotEmpty) ...[
                    const Text(
                      'Prix par niveau:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...program.priceByLevel.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              program.getLevelLabel(entry.key),
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              program.getFormattedPrice(entry.key) ?? 'N/A',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                  
                  const Text(
                    'Filières disponibles:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...program.specialties.map((specialty) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProgramDetailScreen(
                                program: program,
                                universityName: university.name,
                                specialtyName: specialty.name,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      specialty.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      specialty.description,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (specialty.specificRequirements != null && 
                                        specialty.specificRequirements!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prérequis: ${specialty.specificRequirements!.join(", ")}',
                                        style: TextStyle(
                                          color: Colors.orange[600],
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdmissionRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: university.generalAdmissionRequirements!.map((requirement) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  requirement,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticalInfo(BuildContext context) {
    return Column(
      children: [
        if (university.tuitionFee != null)
          _buildInfoRow(
            Icons.attach_money,
            'Frais de scolarité',
            '${university.tuitionFee!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA/an',
          ),
        
        _buildInfoRow(
          Icons.school,
          'Type d\'établissement',
          _getTypeLabel(university.type),
        ),
        
        if (university.address != null)
          _buildInfoRow(
            Icons.location_on,
            'Adresse',
            university.address!,
          ),

        // Distance si disponible
        Consumer<AppProvider>(
          builder: (context, provider, child) {
            if (provider.userLatitude != null && provider.userLongitude != null) {
              final distance = university.distanceFrom(
                provider.userLatitude!,
                provider.userLongitude!,
              );
              return _buildInfoRow(
                Icons.directions,
                'Distance',
                '${distance.toStringAsFixed(1)} km de votre position',
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        if (university.contact != null)
          _buildContactRow(
            Icons.phone,
            'Téléphone',
            university.contact!,
            () => _launchPhone(university.contact!),
          ),
        
        if (university.email != null)
          _buildContactRow(
            Icons.email,
            'Email',
            university.email!,
            () => _launchEmail(university.email!),
          ),
        
        if (university.website != null)
          _buildContactRow(
            Icons.language,
            'Site web',
            university.website!,
            () => _launchUrl(university.website!),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.launch,
                size: 16,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez vous connecter pour ajouter cette université à vos favoris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigation vers l'écran de connexion
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
