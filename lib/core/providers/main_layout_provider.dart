import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../config/app_constants.dart';

class MainLayoutProvider with ChangeNotifier {
  final SidebarXController _sidebarController = SidebarXController(
    selectedIndex: 0,
  );
  List<SidebarXItem> _menuItems = [];

  SidebarXController get sidebarController => _sidebarController;
  List<SidebarXItem> get menuItems => _menuItems;

  void setMenuItems(UserRole role) {
    _menuItems = [
      SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
      if (role == UserRole.admin || role == UserRole.manager)
        SidebarXItem(icon: Icons.people, label: 'Customers'),
      SidebarXItem(icon: Icons.business, label: 'Employers'),
      SidebarXItem(icon: Icons.attach_money, label: 'Cashflow'),
      SidebarXItem(icon: Icons.settings, label: 'Settings'),
    ];
    notifyListeners();
  }
}
