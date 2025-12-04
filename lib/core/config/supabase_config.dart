import 'package:rmn_accounts/core/storage/secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://ojhlkzuuuhgvykrclzlx.supabase.co';
  static const String key =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qaGxrenV1dWhndnlrcmNsemx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNjU0OTcsImV4cCI6MjA2MDc0MTQ5N30.CvJTERF0Nvak-8OFUUbfitiT3a4_wSXWAHDsYUBNABs';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: key,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: const SecureLocalStorage(),
        autoRefreshToken: true,
      ),
    );
  }
}
