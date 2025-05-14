import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
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

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
        setState(() {
          _loadingPermission = false;
        });
      }
    } catch (e) {
      print('Error checking location permission: $e');
      if (mounted) {
        setState(() {
          _permissionError = 'Lỗi khi kiểm tra quyền vị trí: $e';
          _loadingPermission = false;
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
                      final locationCubit = context.read<LocationCubit>();
                      locationCubit.getLocationStream(widget.user.id);
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
      create: (context) {
        try {
          return LocationCubit(
            updateLocation: sl<UpdateLocation>(),
            getLocationStream: sl<GetLocationStream>(),
          )..getLocationStream(widget.user.id);
        } catch (e) {
          print('Error creating LocationCubit: $e');
          // Trả về LocationCubit với trạng thái lỗi
          final cubit = LocationCubit(
            updateLocation: sl<UpdateLocation>(),
            getLocationStream: sl<GetLocationStream>(),
          );
          cubit.emit(LocationError('Lỗi khởi tạo: ${e.toString()}'));
          return cubit;
        }
      },
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
                    context.read<LocationCubit>().getLocationStream(widget.user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang làm mới dữ liệu vị trí...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    print('Error refreshing location data: $e');
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
                            context.read<LocationCubit>().getLocationStream(widget.user.id);
                          } catch (e) {
                            print('Error retrying location stream: $e');
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
                            try {
                              context.read<LocationCubit>().updateLocation(widget.user.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đang cập nhật vị trí...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              print('Error updating location: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
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