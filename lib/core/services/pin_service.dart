import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Low-level service for secure PIN storage using platform keystore.
/// Stores only SHA-256 hash of PIN; never plain text.
class PinService {
  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const String _pinHashKey = 'elderassist_pin_hash';

  final FlutterSecureStorage _storage;

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String createPinHash(String pin) => _hashPin(pin);

  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<bool> verifyPin(String inputPin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    return stored == _hashPin(inputPin);
  }

  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _pinHashKey);
    return stored != null && stored.isNotEmpty;
  }
}
