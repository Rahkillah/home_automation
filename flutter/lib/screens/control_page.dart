// lib/screens/control_page.dart
import 'package:flutter/material.dart';
import '../services/esp32_service.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ESP32Service _esp32Service = ESP32Service();
  bool light1 = false;
  bool light2 = false;
  bool door = false;
  bool window = false;
  int acStatus = 0;

  Future<void> _sendCommand(String command, dynamic value) async {
    try {
      await _esp32Service.sendCommand(command, value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyée avec succès')),
      );
    } catch (e) {
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
          title: const Text('Lumière intérieure 1'),
          value: light1,
          onChanged: (bool value) {
            setState(() => light1 = value);
            _sendCommand('led1', value ? 1 : 0);
          },
        ),
        SwitchListTile(
          title: const Text('Lumière intérieure 2'),
          value: light2,
          onChanged: (bool value) {
            setState(() => light2 = value);
            _sendCommand('led2', value ? 1 : 0);
          },
        ),
        SwitchListTile(
          title: const Text('Porte'),
          value: door,
          onChanged: (bool value) {
            setState(() => door = value);
            _sendCommand('doorStatus', value);
          },
        ),
        SwitchListTile(
          title: const Text('Fenêtre'),
          value: window,
          onChanged: (bool value) {
            setState(() => window = value);
            _sendCommand('windowStatus', value);
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
              setState(() => acStatus = value!);
              _sendCommand('acStatus', value);
            },
          ),
        ),
      ],
    );
  }
}
