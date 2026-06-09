import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Armazenamento chave→valor cifrado em repouso pelo SO.
///
/// Abstrato para permitir fakes nos testes. A implementação concreta delega à
/// camada nativa, que cifra com o Keychain (macOS) ou DPAPI (Windows). Os
/// valores trafegam como strings opacas; nada é mantido em texto puro em disco.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Implementação sobre o canal nativo `dry_eye_widget/secure_store`.
class ChannelSecureStore implements SecureKeyValueStore {
  const ChannelSecureStore();

  static const MethodChannel _channel =
      MethodChannel('dry_eye_widget/secure_store');

  @override
  Future<String?> read(String key) async {
    try {
      return await _channel.invokeMethod<String>('read', {'key': key});
    } catch (e) {
      debugPrint('SecureStore.read indisponível ($e).');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('write', {'key': key, 'value': value});
    } catch (e) {
      debugPrint('SecureStore.write indisponível ($e).');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _channel.invokeMethod<void>('delete', {'key': key});
    } catch (e) {
      debugPrint('SecureStore.delete indisponível ($e).');
    }
  }
}
