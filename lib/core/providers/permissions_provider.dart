import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class PermissionsProvider with ChangeNotifier {
  UserRole? _userRole;

  UserRole? get userRole => _userRole;

  void setUserRole(UserRole role) {
    _userRole = role;
    notifyListeners();
  }

  bool canEdit(BuildContext context) {
    if (_userRole == UserRole.admin) return true;
    _showPermissionRequestDialog(context);
    return false;
  }

  bool canDelete(BuildContext context) {
    if (_userRole == UserRole.admin) return true;
    _showPermissionRequestDialog(context);
    return false;
  }

  void _showPermissionRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Please contact admin for edit/delete permissions',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
