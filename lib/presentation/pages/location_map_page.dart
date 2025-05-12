import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/user.dart';
import '../features/location/cubit/location_cubit.dart';
import '../features/location/widgets/location_map.dart';

class LocationMapPage extends StatelessWidget {
  final User user;

  const LocationMapPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationCubit(
        updateLocation: context.read(),
        getLocationStream: context.read(),
      )..getLocationStream(user.id),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Vị trí của ${user.name}'),
        ),
        body: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            if (state is LocationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LocationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LocationCubit>().getLocationStream(user.id);
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (state is LocationLoaded) {
              final location = state.location;
              final hasLocation = location != null;

              return Column(
                children: [
                  Expanded(
                    child: hasLocation
                        ? LocationMap(
                            initialPosition: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId(user.id),
                                position: LatLng(
                                  location.latitude,
                                  location.longitude,
                                ),
                                infoWindow: InfoWindow(
                                  title: user.name,
                                  snippet: 'Cập nhật: ${_formatDateTime(location.timestamp)}',
                                ),
                              ),
                            },
                          )
                        : const Center(
                            child: Text('Chưa có vị trí'),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<LocationCubit>().updateLocation(user.id);
                      },
                      child: const Text('Cập nhật vị trí'),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('Không có dữ liệu'));
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
} 