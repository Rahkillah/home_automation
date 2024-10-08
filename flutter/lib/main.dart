import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // Ajout de cette importation

const String ESP32_IP = '192.168.239.123'; // Exemple d'adresse IP

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TECHNOLOGIES DE L\'HABITAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    HomeContent(),
    ControlPage(),
    SecurityPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technologies de l\'habitat')),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_remote), label: 'Contrôle'),
          BottomNavigationBarItem(
              icon: Icon(Icons.security), label: 'Sécurité'),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

double convertLuminosity(int value) {
  // Vérifiez que la valeur est dans la plage attendue
  if (value >= 60 && value <= 4095) {
    return ((4095 - value) / (4095 - 60)) * 100; // Convertit en pourcentage
  }
  return 0; // Retourne 0% si la valeur est hors plage
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic> homeData = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchHomeData();
    _startPeriodicFetch();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Annuler le timer lors de la destruction
    super.dispose();
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchHomeData();
    });
  }

  Future<void> fetchHomeData() async {
    try {
      final response = await http.get(Uri.parse('http://$ESP32_IP/datasend'));
      if (response.statusCode == 200) {
        setState(() {
          homeData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load home data');
      }
    } catch (e) {
      print('Error fetching home data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion au serveur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchHomeData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          InfoCard('Température', '${homeData['temperature'] ?? '--'}°C'),
          InfoCard('Humidité', '${homeData['humidity'] ?? '--'}%'),
          InfoCard('Batterie', '${homeData['battLevel'] ?? '--'}%'),
          InfoCard('Luminosité',
              '${homeData['sunLevel'] != null ? convertLuminosity(homeData['sunLevel']).toStringAsFixed(1) : '--'}%'),
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

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool light1 = false;
  bool light2 = false;
  bool door = false;
  bool window = false;
  int acStatus = 0;

  Future<void> sendCommand(String command, dynamic value) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ESP32_IP/datarecived'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({command: value}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande envoyée avec succès')),
        );
      } else {
        throw Exception('Failed to send command');
      }
    } catch (e) {
      print('Error sending command: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur d\'envoi de la commande')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SwitchListTile(
          title: const Text('Lumière'),
          value: light1,
          onChanged: (bool value) {
            setState(() {
              light1 = value;
            });
            sendCommand('led1', value ? 1 : 0);
          },
        ),
        SwitchListTile(
          title: const Text('Porte'),
          value: door,
          onChanged: (bool value) {
            setState(() {
              door = value;
            });
            sendCommand('dorStatus', value);
          },
        ),
        SwitchListTile(
          title: const Text('Fenêtre'),
          value: window,
          onChanged: (bool value) {
            setState(() {
              window = value;
            });
            sendCommand('WindowStatu', value);
          },
        ),
        ListTile(
          title: const Text('Climatisation'),
          trailing: DropdownButton<int>(
            value: acStatus,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Arrêt')),
              DropdownMenuItem(value: 1, child: Text('Chauffage')),
              DropdownMenuItem(value: -1, child: Text('Refroidissement')),
            ],
            onChanged: (int? value) {
              setState(() {
                acStatus = value!;
              });
              sendCommand('chofage', value);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Chauffe-eaux'),
          value: light2,
          onChanged: (bool value) {
            setState(() {
              light2 = value;
            });
            sendCommand('led2', value ? 1 : 0);
          },
        ),
      ],
    );
  }
}

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool intruderDetected = false;

  @override
  void initState() {
    super.initState();
    fetchSecurityData();
  }

  Future<void> fetchSecurityData() async {
    try {
      final response = await http.get(Uri.parse('http://$ESP32_IP/datasend'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          intruderDetected = data['intruStatus'] ?? false;
        });
      } else {
        throw Exception('Failed to load security data');
      }
    } catch (e) {
      print('Error fetching security data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion au serveur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchSecurityData,
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
