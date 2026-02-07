
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
// import 'firebase_options.dart'; // User needs to add this or manual config

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isFirebaseInitialized = false;
  String? errorMessage;

  try {
    // Try to initialize. 
    // On Android/iOS, this uses google-services.json / GoogleService-Info.plist.
    // On Web/Windows, this needs options passed in.
    await Firebase.initializeApp();
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase init failed: $e");
    errorMessage = e.toString();
  }

  runApp(MyApp(
    isFirebaseInitialized: isFirebaseInitialized,
    errorMessage: errorMessage,
  ));
}

class MyApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  final String? errorMessage;

  const MyApp({
    super.key, 
    required this.isFirebaseInitialized,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // If Firebase isn't initialized, show an error screen instead of the app
    if (!isFirebaseInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Configuration Error",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Firebase failed to initialize.",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage ?? "Unknown error",
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage?.contains("FirebaseOptions") ?? false)
                    const Text(
                      "Hint: You are likely running on Web or Windows without configuration. \n\n"
                      "To fix this:\n"
                      "1. Connect an Android Emulator/Device and run on that.\n"
                      "2. OR Configure specifically for Web/Windows using FlutterFire CLI.",
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Rablo Chat App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user == null ? const LoginScreen() : const HomeScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
