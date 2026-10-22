import 'package:flutter/material.dart';

class ExamenController extends ChangeNotifier {
  bool _isExamenMode = false;
  bool _forceOverride = false;

  bool get isExamenMode => _forceOverride || _isExamenMode;

  ExamenController() {
    _checkCircadianHour();
  }

  void _checkCircadianHour() {
    final now = DateTime.now();
    final hour = now.hour;
    // Between 8:00 PM (20:00) and 5:00 AM (05:00)
    _isExamenMode = (hour >= 20 || hour < 5);
  }

  void toggleExamenPreview() {
    _forceOverride = !_forceOverride;
    notifyListeners();
  }
}
