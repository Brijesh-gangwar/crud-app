# 📝 Task Manager App

A powerful and elegant Task Management Flutter application using:

- Firebase Authentication (Google Sign-In)
- Local Storage (SQLite)
- Realtime Sync with Firebase Realtime Database
- BLoC State Management
- Theme Toggle (with SharedPreferences)
- Clean Architecture

---

## 🚀 Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/task_manager_flutter.git
   cd task_manager_flutter

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get

3. **Go to Firebase Console**
- Create a project
- Enable Authentication → Sign-in Method → Google
- Add Android and/or iOS app under project settings
- Download google-services.json (for Android) or GoogleService-Info.plist (for iOS)
- Place them in respective directories:
```bash
android/app/google-services.json

4. **Run the App**
   ```bash 
   flutter run
