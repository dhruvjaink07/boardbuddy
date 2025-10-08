import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:boardbuddy/firebase_options.dart';
import 'package:boardbuddy/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/user/data/user_service.dart';
import 'package:boardbuddy/features/files/services/cloudinary_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize CloudinaryService (this will register Hive adapters)
  try {
    await CloudinaryService.instance.init();
    print('✅ CloudinaryService initialized successfully');
  } catch (e) {
    print('❌ Error initializing CloudinaryService: $e');
  }

  // Listen for auth state changes and create/update user profile
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      try {
        await UserService.instance.createOrUpdateUser(user);
        print('✅ User profile updated: ${user.email}');
        
        // Process any pending invitations
        if (user.email != null) {
          await BoardFirestoreService.instance.processPendingInvitations(user.email!);
          print('✅ Pending invitations processed for: ${user.email}');
        }
      } catch (e) {
        print('❌ Error processing user auth: $e');
      }
    } else {
      print('🔓 User signed out');
    }
  });

  runApp(const ProviderScope(child: BoardBuddyApp()));
}

class BoardBuddyApp extends StatelessWidget {
  const BoardBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initial = FirebaseAuth.instance.currentUser == null
        ? AppRoutes.authScreen
        : AppRoutes.mainScreen;
        
    return GetMaterialApp(
      title: 'BoardBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      getPages: AppRoutes.routes,
      initialRoute: initial,
      // Add error handling for route issues
      unknownRoute: GetPage(
        name: '/unknown',
        page: () => const Scaffold(
          body: Center(
            child: Text('Page not found'),
          ),
        ),
      ),
      // Handle app lifecycle for proper cleanup
      builder: (context, child) {
        return _AppLifecycleWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

// Wrapper to handle app lifecycle events
class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        print('📱 App paused');
        break;
      case AppLifecycleState.resumed:
        print('📱 App resumed');
        break;
      case AppLifecycleState.detached:
        print('📱 App detached - cleaning up');
        _cleanup();
        break;
      default:
        break;
    }
  }

  Future<void> _cleanup() async {
    try {
      // Cleanup CloudinaryService when app is closing
      await CloudinaryService.instance.dispose();
      print('✅ CloudinaryService disposed');
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
