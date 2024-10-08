// lib/widgets/info_card.dart
import 'package:flutter/material.dart';

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
