import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

class TaskColumn extends StatelessWidget {
  final IconData icon; // Vẫn giữ tham số này để không phải thay đổi các chỗ gọi
  final Color iconBackgroundColor; // Vẫn giữ tham số này
  final String title;
  final String subtitle;
  final Task task;

  const TaskColumn({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    // Màu xanh lấy từ icon T
    final baseColor = Color(0xFF0099e5);
    final lightColor = Color.lerp(baseColor, Colors.white, 0.9)!;
    final mediumColor = Color.lerp(baseColor, Colors.white, 0.7)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: mediumColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thay CircleAvatar bằng Image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'lib/presentation/assets/image/t-letter-icon-2048x2048-6ykae5mu.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Hiển thị description nếu có
          if (task.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 52), // Căn lề với title
                Text(
                  'Mô tả:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: baseColor, // Dùng màu icon
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.description!,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}