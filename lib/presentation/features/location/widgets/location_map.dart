import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LocationMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;

  const LocationMap({
    Key? key,
    required this.initialPosition,
    required this.markers,
  }) : super(key: key);

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _mapLoaded = false;
  bool _mapError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_mapError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải bản đồ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'Vui lòng thử lại sau',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _mapError = false;
                    _errorMessage = '';
                  });
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition,
            zoom: 15,
          ),
          markers: widget.markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            try {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              setState(() {
                _mapLoaded = true;
              });
            } catch (e) {
              print('Error completing map controller: $e');
              setState(() {
                _mapError = true;
                _errorMessage = 'Lỗi khi tạo bản đồ: ${e.toString()}';
              });
            }
          },
          onCameraMove: (_) {
            // Chỉ để bắt lỗi
            try {
              // Không làm gì
            } catch (e) {
              print('Error on camera move: $e');
            }
          },
        ),
        if (!_mapLoaded && !_mapError)
          Container(
            color: Colors.white70,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
} 