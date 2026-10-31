import 'package:flutter/material.dart';

class ExamenController extends ChangeNotifier {
  bool _isExamenMode = false;

  bool get isExamenMode => _isExamenMode;

  ExamenController() {
    // Default to clean light mode (clean white background & blended purple)
    _isExamenMode = false;
  }

  void toggleExamenPreview() {
    _isExamenMode = !_isExamenMode;
    notifyListeners();
  }
}
