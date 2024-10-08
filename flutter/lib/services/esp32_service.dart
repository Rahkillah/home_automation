// lib/services/esp32_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ESP32Service {
  static const String ESP32_IP = '192.168.88.238';
  Timer? _timer;
  StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Future<Map<String, dynamic>> fetchHomeData() async {
    final response = await http.get(Uri.parse('http://$ESP32_IP/datasend'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec de la récupération des données');
    }
  }

  void startFetchingHomeData() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      try {
        final data = await fetchHomeData();
        _controller.sink.add(data); // Envoie les données à tous les auditeurs
      } catch (e) {
        _controller.sink.addError('Erreur lors de la récupération des données');
      }
    });
  }

  Stream<Map<String, dynamic>> getHomeDataStream() {
    return _controller.stream;
  }

  void stopFetchingHomeData() {
    _timer?.cancel();
    _controller.close(); // Ferme le StreamController
  }

  Future<void> sendCommand(String command, dynamic value) async {
    final response = await http.post(
      Uri.parse('http://$ESP32_IP/datarecived'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({command: value}),
    );
    if (response.statusCode != 200) {
      throw Exception('Échec de l\'envoi de la commande');
    }
  }
}
