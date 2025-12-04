import 'package:flutter/foundation.dart';
import 'package:sidebarx/sidebarx.dart';

class SidebarProvider with ChangeNotifier {
  final SidebarXController _controller = SidebarXController(
    selectedIndex: 0,
    extended: true,
  );

  SidebarXController get controller => _controller;

  void setSelectedIndex(int index) {
    _controller.selectIndex(index);
    notifyListeners();
  }
}
