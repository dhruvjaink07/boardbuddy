import 'package:boardbuddy/firebase_options.dart';
import 'package:boardbuddy/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: BoardBuddyApp()));
}

class BoardBuddyApp extends StatelessWidget {
  const BoardBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BoardBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      getPages: AppRoutes.routes,
      initialRoute: AppRoutes.boardScreen, // Define a splash route
    );
  }
}
