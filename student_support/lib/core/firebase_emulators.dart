import 'package:firebase_storage/firebase_storage.dart';

/// Host of the local Firebase Storage emulator, or empty for the cloud bucket.
/// Set at build time, so a normal build can never use the emulator:
///
///   flutter run --dart-define=STORAGE_EMULATOR_HOST=10.0.2.2
///
/// 10.0.2.2 is the computer as seen from an Android emulator. For a phone on
/// USB, run `adb reverse tcp:9199 tcp:9199` and use 127.0.0.1.
const String storageEmulatorHost = String.fromEnvironment(
  'STORAGE_EMULATOR_HOST',
);
const int storageEmulatorPort = 9199;

/// Points Firebase Storage at the emulator when a host was set. Firebase
/// Storage needs the paid Blaze plan, so photos run locally for the demo while
/// Authentication and Firestore stay on the live project.
Future<void> connectStorageEmulator() async {
  if (storageEmulatorHost.isEmpty) return;
  await FirebaseStorage.instance.useStorageEmulator(
    storageEmulatorHost,
    storageEmulatorPort,
  );
}
