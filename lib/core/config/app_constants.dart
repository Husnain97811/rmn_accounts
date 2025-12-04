class AppConstants {
  static const double sideBarWidth = 240;
  static const double defaultPadding = 16.0;
  static const String appTitle = "Real Estate Accounting";
}

enum UserRole {
  admin, // For existing users (3 roles total)
  manager, // For new sign-ups (2 roles)
  accountant; // For new sign-ups (2 roles)

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.accountant:
        return 'Accountant';
    }
  }

  // Helper method for sign-up screen
  static List<UserRole> get signUpRoles => [manager, accountant];
}
