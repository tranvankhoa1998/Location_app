import 'package:flutter/material.dart';
import '../../../domain/entities/task.dart';

class ActiveProjectCard extends StatelessWidget {
  final Color cardColor;
  final double loadingPercent;
  final String title;
  final String subtitle;
  final Task task;  // Thêm task để lấy dữ liệu từ Firestore

  const ActiveProjectCard({
    super.key,
    required this.cardColor,
    required this.loadingPercent,
    required this.title,
    required this.subtitle,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: loadingPercent,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}