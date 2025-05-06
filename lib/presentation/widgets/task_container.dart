import 'package:flutter/material.dart';
import 'package:location_trackingv2/domain/entities/task.dart';

class TaskContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color boxColor;

  const TaskContainer({
    super.key, 
    required this.title,
    required this.subtitle,
    required this.boxColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}