import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/app_logger.dart';

/// Gestionnaire de cache local rapide pour toutes les requêtes GET et données d'écrans
class CacheManager {
  static const String cacheBoxName = 'api_http_cache';
  Box? _box;

  CacheManager();

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(cacheBoxName)) {
        _box = await Hive.openBox(cacheBoxName);
      } else {
        _box = Hive.box(cacheBoxName);
      }
      AppLogger.info('CacheManager initialisé avec succès.');
    } catch (e, stackTrace) {
      AppLogger.error('Erreur initialisation CacheManager: $e', e, stackTrace);
    }
  }

  Box get box {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box(cacheBoxName);
    }
    return _box!;
  }

  /// Génère une clé déterministe pour une URL et ses paramètres
  static String makeKey(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.trim().toLowerCase();
    if (queryParams == null || queryParams.isEmpty) {
      return cleanEndpoint;
    }
    final sortedKeys = queryParams.keys.toList()..sort();
    final paramsString = sortedKeys.map((k) => '$k=${queryParams[k]}').join('&');
    return '$cleanEndpoint?$paramsString';
  }

  /// Enregistre une réponse en cache avec un TTL optionnel (par défaut 24 heures)
  Future<void> cacheResponse(
    String key,
    dynamic data, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    try {
      final payload = {
        'cachedAt': DateTime.now().toIso8601String(),
        'ttlMs': ttl.inMilliseconds,
        'dataJson': jsonEncode(data),
      };
      await box.put(key, payload);
      AppLogger.debug('Données mises en cache pour clé: $key');
    } catch (e) {
      AppLogger.warning('Erreur lors de la mise en cache ($key): $e');
    }
  }

  /// Récupère les données du cache.
  /// Si [ignoreExpiration] est vrai (mode hors-ligne), retourne les données même si le TTL est dépassé.
  dynamic getCachedResponse(
    String key, {
    bool ignoreExpiration = false,
  }) {
    try {
      final raw = box.get(key);
      if (raw == null) return null;

      final Map<dynamic, dynamic> map = raw is Map ? raw : jsonDecode(raw.toString()) as Map;
      final cachedAtStr = map['cachedAt']?.toString();
      final ttlMs = map['ttlMs'] is int ? map['ttlMs'] as int : null;

      if (cachedAtStr != null && ttlMs != null && !ignoreExpiration) {
        final cachedAt = DateTime.tryParse(cachedAtStr);
        if (cachedAt != null) {
          final isExpired = DateTime.now().difference(cachedAt).inMilliseconds > ttlMs;
          if (isExpired) {
            AppLogger.debug('Cache expiré pour la clé: $key');
            return null;
          }
        }
      }

      if (map.containsKey('dataJson') && map['dataJson'] != null) {
        return jsonDecode(map['dataJson'] as String);
      }

      return deepCast(map['data']);
    } catch (e) {
      AppLogger.warning('Erreur lecture cache ($key): $e');
      return null;
    }
  }

  /// Convertit récursivement les Maps en Map<String, dynamic> pour éviter les erreurs de type cast
  static dynamic deepCast(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), deepCast(v)));
    } else if (value is List) {
      return value.map(deepCast).toList();
    }
    return value;
  }

  /// Invalide une clé spécifique
  Future<void> invalidateKey(String key) async {
    try {
      await box.delete(key);
      AppLogger.debug('Clé invalidée dans le cache: $key');
    } catch (e) {
      AppLogger.warning('Erreur invalidation clé ($key): $e');
    }
  }

  /// Invalide toutes les clés commençant par un préfixe (ex: "/volailler/tasks" ou "/activities")
  Future<void> invalidatePrefix(String prefix) async {
    try {
      final cleanPrefix = prefix.trim().toLowerCase();
      final keysToDelete = box.keys.where((k) => k.toString().toLowerCase().startsWith(cleanPrefix)).toList();
      for (final key in keysToDelete) {
        await box.delete(key);
      }
      AppLogger.debug('${keysToDelete.length} entrées invalidées pour le préfixe: $prefix');
    } catch (e) {
      AppLogger.warning('Erreur invalidation préfixe ($prefix): $e');
    }
  }

  /// Nettoie l'ensemble du cache
  Future<void> clearAll() async {
    try {
      await box.clear();
      AppLogger.info('Cache HTTP local entièrement vidé.');
    } catch (e) {
      AppLogger.error('Erreur vidage complet du cache: $e');
    }
  }
}
