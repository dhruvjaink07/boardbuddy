import 'package:boardbuddy/features/auth/presentation/auth_screen.dart';
import 'package:boardbuddy/features/board/presentation/board_view_screen.dart';
import 'package:boardbuddy/features/home/presentation/board_screen.dart';
import 'package:boardbuddy/features/main_screen.dart';
import 'package:boardbuddy/features/onboarding/onboarding_screen.dart';
import 'package:boardbuddy/features/onboarding/splash_screen.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class AppRoutes {
  static const String splashScreen = '/splash-screen';
  static const String onBoardingScreen = '/on-boarding-screen';
  static const String authScreen = '/auth-screen';
  static const String boardScreen = '/board-screen';
  static const String mainScreen = '/main-screen';
  static const String boardViewScreen = '/board-view-screen';
  static final List<GetPage> routes = [
    GetPage(name: splashScreen, page: () => SplashScreen()),
    GetPage(name: onBoardingScreen, page: () => OnboardingScreen()),
    GetPage(name: authScreen, page: () => AuthScreen()),
    GetPage(name: boardScreen, page: () => BoardScreen()),
    GetPage(name: mainScreen, page: () => MainScreen()),
    GetPage(name: boardViewScreen, page: () => BoardViewScreen())
  ];
}
