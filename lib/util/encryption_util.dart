// lib/util/encryption_util.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

/// Utility for performing secure data encryption and decryption.
///
/// Uses AES-GCM 256-bit encryption with PBKDF2 key derivation for strong security.
class EncryptionUtil {
  static final _algo = AesGcm.with256bits();

  /// Legacy version of the encryption wrapper format (150,000 iterations).
  static const wrapperVersionV1 = 'LWENC-1';

  /// Current version of the encryption wrapper format (600,000 iterations).
  static const wrapperVersionV2 = 'LWENC-2';

  /// Encrypts [plaintext] using a [passphrase].
  ///
  /// Returns a map containing the version, salt, nonce, cipher text, and MAC.
  static Future<Map<String, dynamic>> encryptString(
    String plaintext,
    String passphrase,
  ) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    // Use 600,000 iterations for new encryptions
    final key = await _deriveKey(passphrase, salt, iterations: 600000);
    final box = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    return {
      'enc': wrapperVersionV2, // Use new version format
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  static Future<String> decryptToString(
    Map<String, dynamic> wrapper,
    String passphrase,
  ) async {
    final String version = wrapper['enc'] as String? ?? wrapperVersionV1;
    if (version != wrapperVersionV1 && version != wrapperVersionV2) {
      throw ArgumentError('Unknown encryption wrapper: $version');
    }

    // Determine the number of iterations based on the wrapper version
    final int iterations = (version == wrapperVersionV2) ? 600000 : 150000;

    final salt = base64Decode(wrapper['salt'] as String);
    final nonce = base64Decode(wrapper['nonce'] as String);
    final cipher = base64Decode(wrapper['cipher'] as String);
    final mac = Mac(base64Decode(wrapper['mac'] as String));
    final key = await _deriveKey(passphrase, salt, iterations: iterations);
    final clear = await _algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return utf8.decode(clear);
  }

  static Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt, {
    int iterations = 150000,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
