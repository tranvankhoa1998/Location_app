import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({Key? key}) : super(key: key);

  @override
  _LocationHistoryScreenState createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  List<Map<String, dynamic>> _locationHistory = [];
  bool _isLoading = true;
  StreamSubscription? _locationSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadLocationHistory();
    _listenToLocationUpdates();
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _loadLocationHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final ref = FirebaseDatabase.instance
          .ref()
          .child('locations')
          .child(currentUser.uid);
      
      final snapshot = await ref.get();
      
      List<Map<String, dynamic>> history = [];
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Nếu chỉ có một entry (current location)
        if (data.containsKey('latitude')) {
          history.add({
            'latitude': (data['latitude'] as num).toDouble(),
            'longitude': (data['longitude'] as num).toDouble(),
            'timestamp': data['timestamp'] as int,
            'accuracy': data['accuracy'] != null ? (data['accuracy'] as num).toDouble() : 0.0,
            'speed': data['speed'] != null ? (data['speed'] as num).toDouble() : 0.0,
          });
        } else {
          // Nếu có nhiều entries (history)
          data.forEach((key, value) {
            if (value is Map) {
              final locationData = Map<String, dynamic>.from(value);
              if (locationData.containsKey('latitude') && 
                  locationData.containsKey('longitude') && 
                  locationData.containsKey('timestamp')) {
                history.add({
                  'latitude': (locationData['latitude'] as num).toDouble(),
                  'longitude': (locationData['longitude'] as num).toDouble(),
                  'timestamp': locationData['timestamp'] as int,
                  'accuracy': locationData['accuracy'] != null ? (locationData['accuracy'] as num).toDouble() : 0.0,
                  'speed': locationData['speed'] != null ? (locationData['speed'] as num).toDouble() : 0.0,
                });
              }
            }
          });
        }
      }
      
      // Sắp xếp theo thời gian mới nhất
      history.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      
      setState(() {
        _locationHistory = history;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Lỗi load location history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _listenToLocationUpdates() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final ref = FirebaseDatabase.instance
        .ref()
        .child('locations')
        .child(currentUser.uid);
    
    _locationSubscription = ref.onValue.listen((event) {
      if (mounted) {
        _loadLocationHistory(); // Reload khi có update
      }
    });
  }
  
  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
  
  String _formatCoordinate(double value) {
    return value.toStringAsFixed(6);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử vị trí'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocationHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locationHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có dữ liệu vị trí',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hãy sử dụng tính năng Test Location để tạo dữ liệu',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locationHistory.length,
                  itemBuilder: (context, index) {
                    final location = _locationHistory[index];
                    final isLatest = index == 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isLatest ? 4 : 2,
                      color: isLatest ? Colors.green.shade50 : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isLatest ? Icons.my_location : Icons.location_on,
                                  color: isLatest ? Colors.green : Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isLatest ? 'Vị trí hiện tại' : 'Vị trí cũ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isLatest ? Colors.green : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                if (isLatest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'LATEST',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                const Icon(Icons.location_pin, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lat: ${_formatCoordinate(location['latitude'])}\nLng: ${_formatCoordinate(location['longitude'])}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(location['timestamp']),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            
                            if (location['accuracy'] > 0 || location['speed'] > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (location['accuracy'] > 0) ...[
                                    const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Độ chính xác: ${location['accuracy'].toStringAsFixed(1)}m',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                  if (location['accuracy'] > 0 && location['speed'] > 0)
                                    const SizedBox(width: 16),
                                  if (location['speed'] > 0) ...[
                                    const Icon(Icons.speed, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tốc độ: ${location['speed'].toStringAsFixed(1)} m/s',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadLocationHistory,
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
