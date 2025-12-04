// services/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = FlutterSecureStorage();

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'last_user_email', value: email);
    await _storage.write(key: 'last_user_password', value: password);
  }

  static Future<Map<String, String>> getCredentials() async {
    final email = await _storage.read(key: 'last_user_email');
    final password = await _storage.read(key: 'last_user_password');
    return {'email': email ?? '', 'password': password ?? ''};
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: 'last_user_email');
    await _storage.delete(key: 'last_user_password');
  }
}
