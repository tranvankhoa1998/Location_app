import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/entities/user.dart';

class UserLocationScreen extends StatelessWidget {
  final User user;

  const UserLocationScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vị trí người dùng'),
      ),
      body: user.location == null
          ? const Center(
              child: Text('Người dùng chưa chia sẻ vị trí'),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  user.location!.latitude,
                  user.location!.longitude,
                ),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(user.id),
                  position: LatLng(
                    user.location!.latitude,
                    user.location!.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: 'Người dùng',
                    snippet: 'Cập nhật: ${_formatDateTime(user.location!.timestamp)}',
                  ),
                ),
              },
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
} 