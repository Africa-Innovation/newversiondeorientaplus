import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/university_list_widget.dart';
import '../widgets/home_header_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    bool locationObtained = await provider.requestUserLocation();
    
    if (locationObtained) {
      print('✅ Localisation obtenue avec succès');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localisation activée avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('❌ Impossible d\'obtenir la localisation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'obtenir la localisation'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin
    
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
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.userCity ?? 'Localisation non disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.hasUserLocation ? Icons.location_on : Icons.location_off,
                  color: provider.hasUserLocation ? Colors.green : Colors.grey,
                ),
                onPressed: () async {
                  await _requestLocationPermission();
                },
                tooltip: provider.hasUserLocation 
                    ? 'Localisation activée' 
                    : 'Activer la localisation',
              );
            },
          ),
        ],
      ),
      body: Selector<AppProvider, bool>(
        selector: (context, provider) => provider.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return const Column(
            children: [
              // En-tête avec recherche et infos
              HomeHeaderWidget(),
              
              // Liste des universités
              Expanded(
                child: UniversityListWidget(),
              ),
            ],
          );
        },
      ),
    );
  }
}
