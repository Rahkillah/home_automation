// lib/screens/security_page.dart
import 'package:flutter/material.dart';
import '../services/esp32_service.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final ESP32Service _esp32Service = ESP32Service();
  bool intruderDetected = false;

  @override
  void initState() {
    super.initState();
    _fetchSecurityData();
  }

  Future<void> _fetchSecurityData() async {
    try {
      final data = await _esp32Service.fetchHomeData();
      setState(() => intruderDetected = data['intruStatus'] ?? false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion au serveur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchSecurityData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Statut de sécurité',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Icon(
                    intruderDetected ? Icons.warning : Icons.security,
                    size: 48,
                    color: intruderDetected ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    intruderDetected
                        ? 'Intrusion détectée!'
                        : 'Aucune intrusion',
                    style: TextStyle(
                        fontSize: 24,
                        color: intruderDetected ? Colors.red : Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
