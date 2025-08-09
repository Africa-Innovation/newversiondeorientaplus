import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/advertisement.dart';
import '../providers/admin_advertisement_provider.dart';
import 'admin_advertisement_form_screen.dart';

class AdminAdvertisementListScreen extends StatefulWidget {
  const AdminAdvertisementListScreen({super.key});

  @override
  State<AdminAdvertisementListScreen> createState() => _AdminAdvertisementListScreenState();
}

class _AdminAdvertisementListScreenState extends State<AdminAdvertisementListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les publicités au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminAdvertisementProvider>(context, listen: false).loadAdvertisements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Publicités'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Actives', icon: Icon(Icons.visibility)),
            Tab(text: 'Inactives', icon: Icon(Icons.visibility_off)),
            Tab(text: 'Expirées', icon: Icon(Icons.schedule)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<AdminAdvertisementProvider>(context, listen: false).loadAdvertisements();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<AdminAdvertisementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${provider.error}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAdvertisements(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAdvertisementList(provider.activeAdvertisements, 'Aucune publicité active'),
              _buildAdvertisementList(provider.inactiveAdvertisements, 'Aucune publicité inactive'),
              _buildAdvertisementList(provider.expiredAdvertisements, 'Aucune publicité expirée'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewAdvertisement(),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Pub'),
      ),
    );
  }

  Widget _buildAdvertisementList(List<Advertisement> advertisements, String emptyMessage) {
    if (advertisements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<AdminAdvertisementProvider>(context, listen: false).loadAdvertisements(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: advertisements.length,
        itemBuilder: (context, index) {
          final advertisement = advertisements[index];
          return _buildAdvertisementCard(advertisement);
        },
      ),
    );
  }

  Widget _buildAdvertisementCard(Advertisement advertisement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de la publicité
          if (advertisement.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Container(
                height: 150,
                width: double.infinity,
                child: Image.network(
                  advertisement.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        advertisement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(advertisement),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  advertisement.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Informations détaillées
                Row(
                  children: [
                    Icon(Icons.priority_high, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Priorité: ${advertisement.priority}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${advertisement.startDate.day}/${advertisement.startDate.month} - ${advertisement.endDate.day}/${advertisement.endDate.month}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Actions
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _editAdvertisement(advertisement),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                    ),
                    if (advertisement.isActive)
                      TextButton.icon(
                        onPressed: () => _deactivateAdvertisement(advertisement),
                        icon: const Icon(Icons.visibility_off, size: 16),
                        label: const Text('Désactiver'),
                        style: TextButton.styleFrom(foregroundColor: Colors.orange),
                      ),
                    TextButton.icon(
                      onPressed: () => _deleteAdvertisement(advertisement),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Advertisement advertisement) {
    final now = DateTime.now();
    final isExpired = now.isAfter(advertisement.endDate);
    final isNotStarted = now.isBefore(advertisement.startDate);
    
    String label;
    Color color;
    
    if (!advertisement.isActive) {
      label = 'Inactive';
      color = Colors.grey;
    } else if (isExpired) {
      label = 'Expirée';
      color = Colors.red;
    } else if (isNotStarted) {
      label = 'Planifiée';
      color = Colors.blue;
    } else {
      label = 'Active';
      color = Colors.green;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _createNewAdvertisement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<AdminAdvertisementProvider>(context, listen: false),
          child: const AdminAdvertisementFormScreen(),
        ),
      ),
    );
    
    if (result == true) {
      // Actualiser la liste
      Provider.of<AdminAdvertisementProvider>(context, listen: false).loadAdvertisements();
    }
  }

  void _editAdvertisement(Advertisement advertisement) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<AdminAdvertisementProvider>(context, listen: false),
          child: AdminAdvertisementFormScreen(advertisement: advertisement),
        ),
      ),
    );
    
    if (result == true) {
      // Actualiser la liste
      Provider.of<AdminAdvertisementProvider>(context, listen: false).loadAdvertisements();
    }
  }

  void _deactivateAdvertisement(Advertisement advertisement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver la publicité'),
        content: Text('Voulez-vous vraiment désactiver "${advertisement.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Désactiver'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<AdminAdvertisementProvider>(context, listen: false);
      final success = await provider.deactivateAdvertisement(advertisement.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicité désactivée avec succès'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _deleteAdvertisement(Advertisement advertisement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publicité'),
        content: Text('Voulez-vous vraiment supprimer "${advertisement.title}" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<AdminAdvertisementProvider>(context, listen: false);
      final success = await provider.deleteAdvertisement(advertisement.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicité supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
