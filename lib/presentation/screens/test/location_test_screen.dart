import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/usecases/get_current_location.dart';
import '../../../domain/usecases/update_location.dart';
import '../../../data/datasources/location_data_source.dart';
import 'location_history_screen.dart';
import 'dart:async';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({Key? key}) : super(key: key);

  @override
  _LocationTestScreenState createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  GoogleMapController? _mapController;
  final GetCurrentLocation _getCurrentLocation = GetIt.instance<GetCurrentLocation>();
  final UpdateLocation _updateLocation = GetIt.instance<UpdateLocation>();
  final LocationDataSourceImpl _locationDataSource = LocationDataSourceImpl();
  
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isTracking = false;
  bool _isLoading = false;
  String _locationInfo = 'Chưa có vị trí';
  StreamSubscription? _locationStreamSubscription;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocationOnce();
  }
  
  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _locationDataSource.stopTracking();
    super.dispose();
  }
  
  // Lấy vị trí hiện tại một lần
  Future<void> _getCurrentLocationOnce() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final location = await _getCurrentLocation();
      final position = LatLng(location.latitude, location.longitude);
      
      setState(() {
        _currentPosition = position;
        _locationInfo = 'Lat: ${location.latitude.toStringAsFixed(6)}\n'
                       'Lng: ${location.longitude.toStringAsFixed(6)}\n'
                       'Time: ${location.timestamp.toString().split('.').first}';
        _markers = {
          Marker(
            markerId: const MarkerId('current'),
            position: position,
            infoWindow: const InfoWindow(title: 'Vị trí hiện tại'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          )
        };
      });
      
      // Di chuyển camera đến vị trí hiện tại
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy vị trí: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Cập nhật vị trí và lưu vào Firebase
  Future<void> _updateLocationToFirebase() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Chưa đăng nhập');
      }
      
      await _updateLocation(currentUser.uid);
      
      // Lấy vị trí mới
      await _getCurrentLocationOnce();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật vị trí vào Firebase!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật vị trí: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Bắt đầu/dừng tracking real-time
  Future<void> _toggleTracking() async {
    if (_isTracking) {
      // Dừng tracking
      await _locationDataSource.stopTracking();
      _locationStreamSubscription?.cancel();
      
      setState(() {
        _isTracking = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã dừng tracking vị trí')),
      );
    } else {
      // Bắt đầu tracking
      try {
        await _locationDataSource.startTracking();
        
        // Listen to location stream
        _locationStreamSubscription = _locationDataSource.getLocationStream().listen(
          (location) {
            final position = LatLng(location.latitude, location.longitude);
            
            setState(() {
              _currentPosition = position;
              _locationInfo = 'Lat: ${location.latitude.toStringAsFixed(6)}\n'
                             'Lng: ${location.longitude.toStringAsFixed(6)}\n'
                             'Time: ${location.timestamp.toString().split('.').first}\n'
                             '🔴 TRACKING...';
              _markers = {
                Marker(
                  markerId: const MarkerId('current'),
                  position: position,
                  infoWindow: const InfoWindow(title: 'Vị trí real-time'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                )
              };
            });
            
            // Di chuyển camera theo vị trí mới
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(position),
              );
            }
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi tracking: $error')),
            );
          },
        );
        
        setState(() {
          _isTracking = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bắt đầu tracking vị trí real-time')),
        );
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi bắt đầu tracking: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Test Location & Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Xem lịch sử vị trí',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(10.8231, 106.6297), // Ho Chi Minh City
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: true,
            ),
          ),
          
          // Information Panel
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin vị trí:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _locationInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getCurrentLocationOnce,
                          icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                          label: const Text('Lấy vị trí'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateLocationToFirebase,
                          icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                          label: const Text('Lưu Firebase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                      label: Text(_isTracking ? 'Dừng Tracking' : 'Bắt đầu Tracking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
