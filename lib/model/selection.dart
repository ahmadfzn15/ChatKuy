import 'package:flutter/foundation.dart';

class Selection extends ChangeNotifier {
  bool _selected = false;

  bool get isSelected => _selected;

  void setSelected(bool value) {
    _selected = value;
    notifyListeners();
  }
}
