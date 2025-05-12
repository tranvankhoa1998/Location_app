import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/usecases/update_location.dart';
import '../../../domain/usecases/get_location_stream.dart';

class ShareLocationScreen extends StatefulWidget {
  final User user;
  final UpdateLocation updateLocation;
  final GetLocationStream getLocationStream;

  const ShareLocationScreen({
    Key? key,
    required this.user,
    required this.updateLocation,
    required this.getLocationStream,
  }) : super(key: key);

  @override
  State<ShareLocationScreen> createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chia sẻ vị trí'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: widget.getLocationStream(widget.user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Có lỗi xảy ra'));
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final locationData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final location = Location.fromMap(locationData);

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      location.latitude,
                      location.longitude,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(widget.user.id),
                      position: LatLng(
                        location.latitude,
                        location.longitude,
                      ),
                      infoWindow: InfoWindow(
                        title: 'Vị trí của bạn',
                        snippet: 'Cập nhật: ${_formatDateTime(location.timestamp)}',
                      ),
                    ),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isSharing
                      ? null
                      : () async {
                          setState(() => _isSharing = true);
                          try {
                            await widget.updateLocation(widget.user.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật vị trí'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            setState(() => _isSharing = false);
                          }
                        },
                  child: _isSharing
                      ? const CircularProgressIndicator()
                      : const Text('Cập nhật vị trí'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
} 