import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'utils/language_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await lang.init();
  runApp(const GsoilFlowApp());
}

class GsoilFlowApp extends StatelessWidget {
  const GsoilFlowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GsoilFlow',
    theme: AppTheme.theme,
    debugShowCheckedModeBanner: false,
    initialRoute: AppRoutes.login,
    routes: AppRoutes.routes,
  );
}
