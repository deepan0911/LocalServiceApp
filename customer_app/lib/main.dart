import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/worker_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/chat_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Note: For Web, you MUST provide FirebaseOptions.
    // Run 'flutterfire configure' or fill in your details below.
    await Firebase.initializeApp(
      options: kIsWeb ? const FirebaseOptions(
        apiKey: "REPLACE_WITH_YOUR_KEY",
        appId: "REPLACE_WITH_YOUR_ID",
        messagingSenderId: "REPLACE_WITH_YOUR_SENDER_ID",
        projectId: "REPLACE_WITH_YOUR_PROJECT_ID",
      ) : null,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  ApiClient.init();
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'ServiceHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
