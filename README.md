# 📍 Location Tracking App V2

A comprehensive Flutter location tracking application with real-time GPS monitoring, Firebase integration, and task management capabilities.

## 🚀 Features

### 🌍 Real-time Location Tracking
- **GPS/WiFi/Mobile Network** positioning
- **Real-time location streaming** with automatic updates
- **Distance-based filtering** (updates every 5-10 meters)
- **Background location tracking** support
- **Google Maps integration** with live markers

### 🔥 Firebase Integration (Hybrid Database Approach)
- **Users**: Stored in **Cloud Firestore** for advanced querying
- **Locations**: Stored in **Firebase Realtime Database** for real-time updates
- **Tasks**: Stored in **Firebase Realtime Database** for task management
- **Authentication**: Firebase Auth with email/password

### 📱 Core Functionality
- **User Authentication** (Login/Register/Profile)
- **Location Test Screen** with manual and automatic tracking
- **Location History** with real-time data display
- **Task Management** with CRUD operations
- **Clean Architecture** with Domain-Driven Design

## 🏗️ Architecture

### Clean Architecture Pattern
```
lib/
├── main.dart                    # App entry point
├── injection_container.dart     # Dependency Injection (GetIt)
├── firebase_options.dart        # Firebase configuration
├── data/                        # Data Layer
│   ├── datasources/            # External data sources
│   │   ├── location_data_source.dart        # GPS & Firebase location
│   │   ├── task_realtime_db_datasource.dart # Task management
│   │   └── user_firestore_datasource.dart   # User management
│   ├── models/                 # Data models
│   └── repositories/           # Repository implementations
├── domain/                     # Business Logic Layer
│   ├── entities/              # Core business entities
│   ├── repositories/          # Repository contracts
│   └── usecases/             # Business use cases
└── presentation/             # UI Layer
    ├── screens/              # App screens
    ├── features/             # Feature-specific UI components
    ├── common/               # Shared UI components
    └── theme/                # App theming
```

### 🎯 Design Patterns Used
- **Repository Pattern** for data abstraction
- **BLoC/Cubit Pattern** for state management
- **Dependency Injection** with GetIt
- **Stream Pattern** for real-time data
- **Observer Pattern** for location updates

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.24+ with Dart
- **BLoC/Cubit** for state management
- **GetIt** for dependency injection
- **Google Maps Flutter** for map integration
- **Geolocator** for GPS positioning

### Backend & Services
- **Firebase Auth** for authentication
- **Cloud Firestore** for user data
- **Firebase Realtime Database** for locations & tasks
- **Firebase Storage** for file uploads

### Key Packages
```yaml
dependencies:
  flutter_bloc: ^8.1.6          # State management
  get_it: ^7.7.0                # Dependency injection
  geolocator: ^14.0.0           # GPS location services
  google_maps_flutter: ^2.12.1  # Google Maps integration
  firebase_core: ^3.13.0        # Firebase core
  firebase_auth: ^5.5.3         # Authentication
  cloud_firestore: ^5.6.7       # Firestore database
  firebase_database: ^11.3.5    # Realtime Database
  permission_handler: ^11.3.1   # Permissions
```

## 📱 Screens & Features

### 🏠 Home Screen
- User profile display
- Quick access to location testing
- Task management overview
- Navigation drawer with all features

### 🧪 Location Test Screen
- **"Lấy vị trí"** - Get current GPS location once
- **"Lưu Firebase"** - Save location to Firebase manually
- **"Bắt đầu/Dừng Tracking"** - Toggle real-time tracking
- **Google Maps** with live location markers
- **Coordinate display** with timestamps

### 📊 Location History Screen
- Real-time location data from Firebase
- Formatted coordinates and timestamps
- Location accuracy and speed information
- Latest location highlighted

### 👤 User Management
- Email/password authentication
- User profile with Firestore integration
- Role-based access (user/admin)

### 📋 Task Management
- Create, read, update, delete tasks
- Real-time synchronization
- Numbered task ordering
- Date and description tracking

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24+
- Android Studio / VS Code
- Firebase project setup
- Google Maps API key

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore database for users
4. Create Realtime Database for locations and tasks
5. Add your Android/iOS apps to Firebase
6. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/location_trackingv2.git
cd location_trackingv2

# Install dependencies
flutter pub get

# Configure Firebase
# Place google-services.json in android/app/
# Place GoogleService-Info.plist in ios/Runner/

# Generate Firebase options
flutter packages pub run build_runner build

# Run the app
flutter run
```

### Google Maps Setup
1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com)
2. Enable Maps SDK for Android/iOS
3. Add the API key to:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/AppDelegate.swift`

## 📍 Location Permissions

### Android
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track your position.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your position in background.</string>
```

## 🔥 Firebase Database Structure

### Firestore (Users)
```javascript
users/{userId} {
  name: string,
  email: string,
  role: "user" | "admin",
  createdAt: timestamp,
  // ... other profile fields
}
```

### Realtime Database (Locations & Tasks)
```javascript
{
  "locations": {
    "userId": {
      "latitude": number,
      "longitude": number,
      "timestamp": number
    }
  },
  "tasks": {
    "userId": {
      "taskId": {
        "task": string,
        "description": string,
        "date": number,
        "number": number
      }
    }
  }
}
```

## 🧪 Testing

### Location Testing on Emulator
1. Open Android Emulator
2. Go to **Extended Controls** (three dots)
3. Select **Location** tab
4. Set custom coordinates and send location
5. Test real-time tracking with coordinate changes

### Manual Testing Features
- Authentication flow
- Location permissions
- Real-time GPS tracking
- Firebase data synchronization
- Map marker updates
- Background location updates

## 🏆 Best Practices Implemented

### 🔒 Security
- Firebase Security Rules for database access
- User authentication required for all operations
- Permission-based location access

### 🎯 Performance
- Stream-based real-time updates
- Efficient location filtering (distance-based)
- Optimized Firebase queries
- Background processing for location tracking

### 🧩 Code Quality
- Clean Architecture separation
- SOLID principles
- Dependency injection
- Error handling and logging
- Type safety with Dart

## 🐛 Troubleshooting

### Common Issues
1. **Location permissions denied**
   - Check app settings and grant location permissions
   - Enable location services on device

2. **Firebase connection issues**
   - Verify `google-services.json` placement
   - Check Firebase project configuration
   - Ensure proper package name matching

3. **Google Maps not loading**
   - Verify API key configuration
   - Check Maps SDK is enabled
   - Ensure billing is set up for Google Cloud

4. **Background tracking not working**
   - Check background app permissions
   - Test on physical device (not emulator)
   - Verify battery optimization settings

## 📈 Future Enhancements

- [ ] **Geofencing** - Location-based alerts
- [ ] **Route Planning** - Navigation between locations
- [ ] **Location Sharing** - Share location with other users
- [ ] **Offline Mode** - Cache locations when offline
- [ ] **Push Notifications** - Location-based notifications
- [ ] **Advanced Analytics** - Location history analysis
- [ ] **Export Features** - Export location data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name**
- GitHub: [@your-username](https://github.com/your-username)
- Email: your.email@example.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- Google Maps team for mapping services
- Open source community for inspiration

---

⭐ **Star this repository if it helped you!**
