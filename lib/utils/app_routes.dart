import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/start_shift_screen.dart';
import '../screens/choose_family_screen.dart';
import '../screens/choose_subfamily_screen.dart';
import '../screens/choose_machine_screen.dart';
import '../screens/operation_screen.dart';
import '../screens/post_op_screen.dart';
import '../screens/end_shift_screen.dart';
import '../screens/report_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const login          = '/';
  static const register       = '/register';
  static const welcome        = '/welcome';
  static const startShift     = '/start_shift';
  static const chooseFamily   = '/choose_family';
  static const chooseSubfamily= '/choose_subfamily';
  static const chooseMachine  = '/choose_machine';
  static const operation      = '/operation';
  static const postOp         = '/post_op';
  static const endShift       = '/end_shift';
  static const report         = '/report';
  static const settings       = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    login:           (_) => const LoginScreen(),
    register:        (_) => const RegisterScreen(),
    welcome:         (_) => const WelcomeScreen(),
    startShift:      (_) => const StartShiftScreen(),
    chooseFamily:    (_) => const ChooseFamilyScreen(),
    chooseSubfamily: (_) => const ChooseSubfamilyScreen(),
    chooseMachine:   (_) => const ChooseMachineScreen(),
    operation:       (_) => const OperationScreen(),
    postOp:          (_) => const PostOpScreen(),
    endShift:        (_) => const EndShiftScreen(),
    report:          (_) => const ReportScreen(),
    settings:        (_) => const SettingsScreen(),
  };
}
