import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  @override
  Future<void> initialize() async {
    // Initialization logic if needed
  }

  @override
  Future<bool> hasAccessToken() async {
    const storage = FlutterSecureStorage();
    return storage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String value) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: supabasePersistSessionKey, value: value);
  }

  @override
  Future<void> removePersistedSession() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: supabasePersistSessionKey);
  }
}
