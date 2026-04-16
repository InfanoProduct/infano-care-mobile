import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PrivacyService {
  final FlutterSecureStorage _storage;
  static const String _keyPath = 'infano_notes_master_key';
  
  Key? _cachedKey;

  PrivacyService(this._storage);

  Future<Key> _getOrGenerateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? existingKey = await _storage.read(key: _keyPath);
    if (existingKey == null) {
      // Generate a new 256-bit key
      final newKey = Key.fromSecureRandom(32);
      await _storage.write(key: _keyPath, value: newKey.base64);
      _cachedKey = newKey;
      return newKey;
    }

    _cachedKey = Key.fromBase64(existingKey);
    return _cachedKey!;
  }

  Future<String?> encrypt(String? plainText) async {
    if (plainText == null || plainText.isEmpty) return null;

    try {
      final key = await _getOrGenerateKey();
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Format: [IV (16 bytes)] + [Ciphertext]
      // We store both as a single base64 string
      final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
      return base64.encode(combined);
    } catch (e) {
      return plainText; // Fallback to plain if encryption fails (should not happen in prod)
    }
  }

  Future<String?> decrypt(String? encryptedData) async {
    if (encryptedData == null || encryptedData.isEmpty) return null;

    try {
      // Check if it's base64, if not, it might be legacy plain text
      final rawData = base64.decode(encryptedData);
      if (rawData.length < 17) return encryptedData; // Not encrypted by our system

      final key = await _getOrGenerateKey();
      final iv = IV(rawData.sublist(0, 16));
      final cipherBytes = rawData.sublist(16);
      
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt(Encrypted(cipherBytes), iv: iv);
      
      return decrypted;
    } catch (e) {
      // If decryption fails, it's likely a legacy plain text or corrupted
      return encryptedData;
    }
  }
}
