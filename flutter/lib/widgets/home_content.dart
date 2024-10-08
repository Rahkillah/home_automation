// lib/widgets/home_content.dart
import 'package:flutter/material.dart';
import 'info_card.dart';
import '../services/esp32_service.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ESP32Service _esp32Service = ESP32Service();
  Map<String, dynamic> homeData = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _esp32Service.fetchHomeData();
      setState(() => homeData = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion au serveur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          InfoCard('Température', '${homeData['temperature'] ?? '--'}°C'),
          InfoCard('Humidité', '${homeData['humidity'] ?? '--'}%'),
          InfoCard('Batterie', '${homeData['battLevel'] ?? '--'}%'),
          InfoCard('Luminosité', '${homeData['sunLevel'] ?? '--'}'),
          InfoCard(
              'Pluie',
              homeData['rainLevel'] != null
                  ? (homeData['rainLevel'] > 500 ? 'Oui' : 'Non')
                  : '--'),
        ],
      ),
    );
  }
}
