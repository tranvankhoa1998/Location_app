// lib/presentation/pages/location_map_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screen_2/location_cubit.dart';
import '../widgets/back_button.dart';
import '../../data/models/location_model.dart';
import '../theme/colors/light_colors.dart';

class LocationMapPage extends StatefulWidget {
  @override
  _LocationMapPageState createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final currentUser = FirebaseAuth.instance.currentUser;
  
  // Vị trí mặc định - Hà Nội, Việt Nam
  final LatLng _defaultLocation = LatLng(21.0278, 105.8342);
  
  // Controller cho việc nhập lat/lng
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  
  // Lưu vị trí hiện tại để có thể thay đổi
  LatLng? _currentPosition;
  bool _showManualControls = false;

  @override
  void initState() {
    super.initState();
    // Tải vị trí hiện tại khi trang được mở
    context.read<LocationCubit>().loadCurrentLocation();
  }
  
  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Di chuyển camera đến vị trí
  Future<void> _animateToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16.0,
        ),
      ),
    );
  }
  
  // Thay đổi vị trí thủ công
  void _changeLocationManually() {
    try {
      final double lat = double.parse(_latController.text);
      final double lng = double.parse(_lngController.text);
      
      setState(() {
        _currentPosition = LatLng(lat, lng);
      });
      
      _animateToPosition(_currentPosition!);
      
      // Tạo location mới
      final newLocation = LocationModel(
        latitude: lat,
        longitude: lng,
        accuracy: 0.0,
        altitude: 0.0,
        speed: 0.0,
        timestamp: DateTime.now(),
      );
      
      // Lưu vị trí mới
      context.read<LocationCubit>().saveCustomLocation(newLocation);
      
      // Ẩn form sau khi cập nhật
      setState(() {
        _showManualControls = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật vị trí mới!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tọa độ không hợp lệ. Vui lòng kiểm tra lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LocationCubit, LocationState>(
          listener: (context, state) {
            if (state is LocationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is LocationLoaded) {
              setState(() {
                _currentPosition = LatLng(
                  state.location.latitude,
                  state.location.longitude,
                );
                
                // Cập nhật controllers
                _latController.text = state.location.latitude.toString();
                _lngController.text = state.location.longitude.toString();
              });
              
              _animateToPosition(_currentPosition!);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // Google Map với vị trí mặc định
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? _defaultLocation,
                    zoom: 16.0,
                  ),
                  markers: state is LocationLoaded 
                      ? state.markers 
                      : {
                          Marker(
                            markerId: MarkerId('default_location'),
                            position: _currentPosition ?? _defaultLocation,
                            infoWindow: InfoWindow(
                              title: 'Vị trí mặc định',
                              snippet: 'Hà Nội, Việt Nam',
                            ),
                          )
                        },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  // Thêm tap để thay đổi vị trí
                  onTap: (LatLng position) {
                    setState(() {
                      _currentPosition = position;
                      _latController.text = position.latitude.toString();
                      _lngController.text = position.longitude.toString();
                    });
                    
                    // Tạo location mới
                    final newLocation = LocationModel(
                      latitude: position.latitude,
                      longitude: position.longitude,
                      accuracy: 0.0,
                      altitude: 0.0,
                      speed: 0.0,
                      timestamp: DateTime.now(),
                    );
                    
                    // Lưu vị trí mới
                    context.read<LocationCubit>().saveCustomLocation(newLocation);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật vị trí mới!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Header
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      CustomBackButton(),
                      SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          'Vị trí của bạn',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Nút cài đặt vị trí thủ công
                      IconButton(
                        icon: Icon(
                          _showManualControls 
                              ? Icons.close 
                              : Icons.edit_location_alt,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            _showManualControls = !_showManualControls;
                          });
                        },
                        tooltip: 'Thay đổi vị trí thủ công',
                      ),
                    ],
                  ),
                ),

                // Thông tin người dùng
                Positioned(
                  top: 80,
                  left: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 12,
                          child: Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                        SizedBox(width: 8),
                        Text(
                          currentUser?.email ?? 'Chưa đăng nhập',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Hiển thị vị trí hiện tại
                if (_currentPosition != null)
                  Positioned(
                    top: 120,
                    left: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                
                // Form nhập vị trí thủ công
                if (_showManualControls)
                  Positioned(
                    top: 160,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Nhập tọa độ thủ công',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _latController,
                                  decoration: InputDecoration(
                                    labelText: 'Vĩ độ (Latitude)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _lngController,
                                  decoration: InputDecoration(
                                    labelText: 'Kinh độ (Longitude)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _changeLocationManually,
                            child: Text('Cập nhật vị trí'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LightColors.kBlue,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Hoặc chỉ cần chạm vào bản đồ để thay đổi vị trí',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Control buttons
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Tracking button
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 10),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<LocationCubit>().toggleLocationTracking();
                          },
                          icon: Icon(
                            state is LocationLoaded && state.isTracking
                                ? Icons.location_off
                                : Icons.location_on,
                            color: Colors.white,
                          ),
                          label: Text(
                            state is LocationLoaded && state.isTracking
                                ? 'Dừng theo dõi'
                                : 'Bắt đầu theo dõi',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state is LocationLoaded && state.isTracking
                                ? Colors.red
                                : LightColors.kGreen,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      // Current location button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (state is LocationLoaded) {
                              _animateToPosition(LatLng(
                                state.location.latitude,
                                state.location.longitude,
                              ));
                            } else {
                              context.read<LocationCubit>().loadCurrentLocation();
                            }
                          },
                          icon: Icon(Icons.my_location, color: Colors.white),
                          label: Text(
                            'Vị trí hiện tại',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LightColors.kBlue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tracking indicator
                if (state is LocationLoaded && state.isTracking)
                  Positioned(
                    top: 80,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TRACKING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                // Loading indicator
                if (state is LocationLoading)
                  Container(
                    color: Colors.black12,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}