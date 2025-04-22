import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({Key? key}) : super(key: key);
  Future<void> _addData(String task) async{
    Timestamp _date = Timestamp.fromDate(DateTime.now());
    CollectionReference tasks = FirebaseFirestore.instance.collection('task');
    
    return tasks
    .add({
      'task': task,
      'date': _date,
      'number':10
    })
    .then((value) => print('thêm task mới'))
    .catchError((error) => print('thêm không thành công'));
  }
    Future<void> _updateData(String id) async{
      CollectionReference tasks = FirebaseFirestore.instance.collection('task');
      return tasks
      .doc(id)
      .update({'number':20})
      .then((value) => print('dữ liệu đã được cập nhập'))
      .catchError((error) => print('chưa cập nhập dữ liệu'));

    }
    Future<void> _deleteData(String id) async{
      CollectionReference tasks = FirebaseFirestore.instance.collection('task');
      return tasks
      .doc(id)
      .delete( )
      .then((value) => print('đã xoá'))
      .catchError((error) => print('xoá thất bại'));

    }
  @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late GoogleMapController mapController;

//   final LatLng _center = const LatLng(45.521563, -122.677433);
//   printf() {
//     // TODO: implement printf
//     throw UnimplementedError();
//   }
//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//   }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.lightBlueAccent,
          displayColor: Colors.lightGreen,
          fontFamily: 'Poppins'
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Location_tracking'),
          elevation: 2,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('task')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Lỗi dữ liệu'),
              );
            }
            if (snapshot.connectionState == ConnectionState.active) {
                return ListView(
                  children: snapshot.data!.docs.map((document) {
                    Map<String, dynamic> data = 
                    document.data()! as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        _updateData(document.id);
                      },
                      child: Card(
                        elevation: 5,
                       child: ListTile(
                        title: Text(data['task']),
                        subtitle: Text(data['number'].toString()),
                        trailing: IconButton(
                          onPressed: (){
                            _deleteData(document.id);
                          }, 
                          icon: const Icon(Icons.delete_forever),
                          ),
                       ), 
                      ),
                    );
                  }).toList(),
                );
              }
            return const Center(
              child: Text('Đang tải ...'),
            );
         }
        // GoogleMap(
        //   onMapCreated: _onMapCreated,
        //   initialCameraPosition: CameraPosition(
        //     target: _center,
        //     zoom: 11.0,
        //   ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            _addData('Create CRUD operation');
          },
          child: const Icon(Icons.add),
       ),
      ),
    ); 
  }
}