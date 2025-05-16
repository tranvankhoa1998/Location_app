import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import '../../../../domain/entities/user.dart';
import '../cubit/location_cubit.dart';
import '../widgets/location_map.dart';
import '../../../../domain/usecases/update_location.dart';
import '../../../../domain/usecases/get_location_stream.dart';

// Lấy GetIt instance
final sl = GetIt.instance;

class LocationMapPage extends StatefulWidget {
  final User user;

  const LocationMapPage({
    super.key,
    required this.user,
  });

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  bool _loadingPermission = false;
  String? _permissionError;
  StreamSubscription? _locationSubscription;
  LocationCubit? _locationCubit;
  bool _isUpdatingLocation = false;
  bool _createOwnCubit = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    // Dọn dẹp tài nguyên
    _locationSubscription?.cancel();
    // Đảm bảo xử lý tất cả các lỗi tiềm ẩn khi dispose
    try {
      // Chỉ đóng cubit nếu chúng ta đã tạo nó, không phải từ BlocProvider
      if (_locationCubit != null && _createOwnCubit) {
        _locationCubit!.close(); // Đóng cubit an toàn, đã cải tiến quản lý stream bên trong
      }
    } catch (e) {
      // Error silently ignored in production
    }
    super.dispose();
  }

  // Kiểm tra quyền truy cập vị trí
  Future<void> _checkLocationPermission() async {
    if (mounted) {
      setState(() {
        _loadingPermission = true;
      });
    }

    try {
      // Kiểm tra dịch vụ vị trí có bật không
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _permissionError = 'Dịch vụ vị trí bị tắt. Vui lòng bật vị trí trên thiết bị của bạn.';
            _loadingPermission = false;
          });
        }
        return;
      }

      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _permissionError = 'Quyền truy cập vị trí bị từ chối. Vui lòng cấp quyền vị trí cho ứng dụng.';
              _loadingPermission = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _permissionError = 'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền vị trí cho ứng dụng.';
            _loadingPermission = false;
          });
        }
        return;
      }

      // Nếu có quyền, tiếp tục
      if (mounted) {
        _createAndInitCubit(); // Tạo và khởi tạo cubit ở đây
        setState(() {
          _loadingPermission = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionError = 'Lỗi khi kiểm tra quyền vị trí: $e';
          _loadingPermission = false;
        });
      }
    }
  }

  // Tạo cubit khi quyền đã được kiểm tra
  void _createAndInitCubit() {
    try {
      // Tạo cubit mới và khởi tạo stream
      _locationCubit = LocationCubit(
        updateLocation: sl<UpdateLocation>(),
        getLocationStream: sl<GetLocationStream>(),
      );
      
      // Đánh dấu cubit này do widget tạo, để hủy đúng cách khi dispose
      _createOwnCubit = true;
      
      // Bảo vệ khỏi lỗi nếu cubit không khởi tạo được
      if (_locationCubit != null) {
        _locationCubit!.getLocationStream(widget.user.id);
      } else {
        throw Exception('LocationCubit could not be initialized');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionError = 'Lỗi khởi tạo: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang kiểm tra quyền
    if (_loadingPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đang kiểm tra quyền vị trí'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kiểm tra quyền truy cập vị trí...'),
            ],
          ),
        ),
      );
    }

    // Nếu có lỗi quyền
    if (_permissionError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi quyền vị trí'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_disabled, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  _permissionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await _checkLocationPermission();
                    if (_permissionError == null && mounted) {
                      // Nếu kiểm tra quyền thành công, làm mới LocationCubit
                      _createAndInitCubit();
                    }
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Nếu có quyền, hiển thị bình thường
    return BlocProvider(
      create: (context) => _locationCubit!,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Vị trí của ${widget.user.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới dữ liệu',
                onPressed: () {
                  try {
                    _locationCubit!.getLocationStream(widget.user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang làm mới dữ liệu vị trí...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              if (state is LocationLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang tải dữ liệu vị trí...'),
                    ],
                  ),
                );
              }

              if (state is LocationError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        onPressed: () {
                          try {
                            _locationCubit!.getLocationStream(widget.user.id);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }

              if (state is LocationLoaded) {
                final location = state.location;

                return Column(
                  children: [
                    // Banner thông tin
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vị trí của bạn được cập nhật lúc ${_formatDateTime(location.timestamp)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tọa độ: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bản đồ
                    Expanded(
                      child: Stack(
                        children: [
                          LocationMap(
                            initialPosition: LatLng(
                              location.latitude,
                              location.longitude,
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
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(location.timestamp),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Nút cập nhật vị trí
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.my_location),
                          label: const Text('Cập nhật vị trí hiện tại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            // Ngăn người dùng nhấn nhiều lần
                            if (_isUpdatingLocation) return;
                            
                            try {
                              setState(() {
                                _isUpdatingLocation = true;
                              });
                              
                              // Hiển thị SnackBar trước khi gọi API để tránh các vấn đề về timing
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đang cập nhật vị trí...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              
                              // Đảm bảo sử dụng Future.delayed để tránh các vấn đề UI thread
                              Future.delayed(Duration.zero, () async {
                                try {
                                  // Thực hiện cập nhật với try-catch riêng
                                  await _locationCubit!.updateLocation(widget.user.id);
                                  
                                  // Chỉ hiển thị thông báo thành công nếu widget vẫn mounted
                                  if (mounted) {
                                    setState(() {
                                      _isUpdatingLocation = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vị trí đã được cập nhật thành công'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    
                                    // Chờ một chút để người dùng thấy thông báo rồi quay lại
                                    await Future.delayed(const Duration(seconds: 1));
                                    
                                    // Nếu widget vẫn mounted, thì quay lại trang trước đó
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      _isUpdatingLocation = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              });
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _isUpdatingLocation = false;
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi nghiêm trọng: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Không có dữ liệu vị trí'),
                    SizedBox(height: 16),
                    Text('Bạn cần cập nhật vị trí để xem trên bản đồ'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 