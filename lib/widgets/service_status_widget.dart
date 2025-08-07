import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_university_service.dart';
import '../services/image_api_service.dart';

class ServiceStatusWidget extends StatefulWidget {
  const ServiceStatusWidget({super.key});

  @override
  State<ServiceStatusWidget> createState() => _ServiceStatusWidgetState();
}

class _ServiceStatusWidgetState extends State<ServiceStatusWidget> {
  bool _firebaseConnected = false;
  bool _apiConnected = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkServicesStatus();
  }

  Future<void> _checkServicesStatus() async {
    setState(() {
      _isChecking = true;
    });

    // Tester Firebase
    try {
      _firebaseConnected = await FirebaseUniversityService.testFirestoreConnection();
    } catch (e) {
      _firebaseConnected = false;
    }

    // Tester API Laravel (seulement si pas sur web)
    if (!kIsWeb) {
      try {
        _apiConnected = await ImageApiService.testConnection();
      } catch (e) {
        _apiConnected = false;
      }
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'État des services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isChecking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _checkServicesStatus,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Firebase Status
            _buildServiceRow(
              '🔥 Firebase Firestore',
              _firebaseConnected,
              'Stockage des données',
            ),
            
            // API Status
            if (kIsWeb)
              _buildServiceRow(
                '🌐 Upload d\'images',
                false,
                'Non disponible sur web',
                isWarning: true,
              )
            else
              _buildServiceRow(
                '🖼️ API Laravel',
                _apiConnected,
                'Upload d\'images',
              ),
            
            const SizedBox(height: 8),
            
            // Platform Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    kIsWeb ? Icons.web : Icons.phone_android,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kIsWeb ? 'Mode Web' : 'Mode Mobile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(String name, bool isConnected, String description, {bool isWarning = false}) {
    Color statusColor;
    IconData statusIcon;
    
    if (isWarning) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (isConnected) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isWarning ? 'Non supporté' : (isConnected ? 'Connecté' : 'Déconnecté'),
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
