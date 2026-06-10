import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  static final AppState _i = AppState._();
  factory AppState() => _i;
  AppState._();

  String? currentUser;
  int?    currentShiftId;

  // Sélections navigation
  String? selectedFamilyCode;
  String? selectedFamilyName;
  String? selectedSubfamilyCode;
  String? selectedSubfamilyName;
  int?    selectedMachineId;
  String? selectedMachineName;

  // Dernière opération
  double? lastOpQty;
  String? lastOpMachine;

  void reset() {
    currentUser      = null;
    currentShiftId   = null;
    clearSelection();
    notifyListeners();
  }

  void clearSelection() {
    selectedFamilyCode     = null;
    selectedFamilyName     = null;
    selectedSubfamilyCode  = null;
    selectedSubfamilyName  = null;
    selectedMachineId      = null;
    selectedMachineName    = null;
  }

  void notify() => notifyListeners();
}

final appState = AppState();
