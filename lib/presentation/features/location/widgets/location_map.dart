import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:io';

class LocationMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;

  const LocationMap({
    super.key,
    required this.initialPosition,
    required this.markers,
  });

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _mapLoaded = false;
  bool _mapError = false;
  String _errorMessage = '';
  bool _userMovedCamera = false; // Theo dõi xem người dùng có tự di chuyển camera không
  
  // Các BehaviorSubject để theo dõi sự kiện di chuyển camera
  CameraPosition? _lastCameraPosition;

  @override
  void initState() {
    super.initState();
    // Chú ý: dòng này gây lỗi vì AndroidGoogleMapsFlutter không có sẵn
    // thay vào đó, chúng ta sẽ cài đặt trong main.dart
    // if (Platform.isAndroid) {
    //   AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
    // }
  }

  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Nếu vị trí ban đầu thay đổi và người dùng chưa tự di chuyển camera, cập nhật camera
    if (oldWidget.initialPosition != widget.initialPosition && !_userMovedCamera) {
      _updateCameraPosition(widget.initialPosition);
    }
    
    // Nếu markers thay đổi, cập nhật UI
    if (oldWidget.markers != widget.markers) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Phương thức để cập nhật vị trí camera
  Future<void> _updateCameraPosition(LatLng position) async {
    if (_controller.isCompleted) {
      try {
        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position,
              zoom: 15,
            ),
          ),
        );
      } catch (e) {
        print('Error updating camera position: $e');
      }
    }
  }

  @override
  void dispose() {
    // Xử lý giải phóng tài nguyên khi widget bị hủy
    if (_controller.isCompleted) {
      _controller.future.then((controller) {
        controller.dispose();
      }).catchError((e) {
        print('Error disposing map controller: $e');
      });
    }
    super.dispose();
  }

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
          compassEnabled: true,
          mapType: MapType.normal,
          // Giảm thiểu lỗi EGL bằng cách sử dụng LiteMode trên máy ảo
          liteModeEnabled: Platform.isAndroid && false, // Tắt lite mode
          trafficEnabled: false, // Tắt hiển thị giao thông
          buildingsEnabled: true, // Bật hiển thị tòa nhà
          indoorViewEnabled: false, // Tắt chế độ xem trong nhà
          onMapCreated: (GoogleMapController controller) {
            try {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              if (mounted) {
                setState(() {
                  _mapLoaded = true;
                });
              }
            } catch (e) {
              print('Error completing map controller: $e');
              if (mounted) {
                setState(() {
                  _mapError = true;
                  _errorMessage = 'Lỗi khi tạo bản đồ: ${e.toString()}';
                });
              }
            }
          },
          onCameraMove: (_) {
            // Bắt lỗi khi di chuyển camera
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