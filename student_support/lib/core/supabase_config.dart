import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

/// Set at build time from the git-ignored supabase.env.json:
///
///   flutter run --dart-define-from-file=supabase.env.json
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

/// Connects the Supabase client that stores incident photos. There is no
/// Supabase sign-in: each request carries the user's Firebase ID token, and
/// the policies in supabase/storage_policies.sql check it.
Future<void> initializeSupabase() async {
  if (!isSupabaseConfigured) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
  );
}
