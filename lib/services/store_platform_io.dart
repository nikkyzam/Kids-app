import 'dart:io' show Platform;

/// The platform name the receipt verifier expects.
///
/// Split behind a conditional import so the web build never reaches
/// `dart:io` at all, rather than relying on a `kIsWeb` guard inside a getter
/// that still has to compile the import.
///
/// macOS is reported as 'ios': StoreKit is one store, and the App Store
/// Server API answers for both from the same transaction id.
String storePlatformName() =>
    Platform.isIOS || Platform.isMacOS ? 'ios' : 'android';
