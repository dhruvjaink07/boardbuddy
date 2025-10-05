import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:boardbuddy/firebase_options.dart';
import 'package:boardbuddy/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/user/data/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Listen for auth state changes and create/update user profile
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      await UserService.instance.createOrUpdateUser(user);
      
      // Process any pending invitations
      if (user.email != null) {
        await BoardFirestoreService.instance.processPendingInvitations(user.email!);
      }
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
        : AppRoutes.boardScreen; // replace with your boards/home route name
    return GetMaterialApp(
      title: 'BoardBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      getPages: AppRoutes.routes,
      initialRoute: initial,
    );
  }
}
