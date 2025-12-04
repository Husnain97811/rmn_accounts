import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_constants.dart';

class PermissionsService {
  final _supabase = Supabase.instance.client;

  Future<bool> checkAdminPermission(String userId) async {
    final response =
        await _supabase
            .from('profiles')
            .select('role')
            .eq('user_id', userId)
            .single();

    return response['role'] == UserRole.admin.name;
  }

  Future<void> requestPermission(String userId) async {
    await _supabase.from('permission_requests').insert({
      'user_id': userId,
      'status': 'pending',
    });
  }
}
