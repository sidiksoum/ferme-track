import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/utils/app_logger.dart';

/// Local storage interface
abstract class LocalStorage {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<void> removeAll(List<String> keys);
}

/// Local storage implementation
class LocalStorageImpl implements LocalStorage {
  final FlutterSecureStorage _secureStorage;

  LocalStorageImpl(this._secureStorage);

  @override
  Future<void> saveString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving string: $key', e, stackTrace);
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e, stackTrace) {
      AppLogger.error('Error reading string: $key', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> saveInt(String key, int value) async {
    try {
      await _secureStorage.write(key: key, value: value.toString());
    } catch (e, stackTrace) {
      AppLogger.error('Error saving int: $key', e, stackTrace);
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null ? int.tryParse(value) : null;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading int: $key', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    try {
      await _secureStorage.write(key: key, value: value.toString());
    } catch (e, stackTrace) {
      AppLogger.error('Error saving bool: $key', e, stackTrace);
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null ? value.toLowerCase() == 'true' : null;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading bool: $key', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e, stackTrace) {
      AppLogger.error('Error removing key: $key', e, stackTrace);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing storage', e, stackTrace);
    }
  }

  @override
  Future<void> removeAll(List<String> keys) async {
    try {
      for (final key in keys) {
        await _secureStorage.delete(key: key);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error removing keys', e, stackTrace);
    }
  }
}

/// Hive Local Cache for large data
class HiveCache {
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      // Register boxes here as needed
      await _openBoxes();
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing Hive', e, stackTrace);
    }
  }

  static Future<void> _openBoxes() async {
    try {
      await Hive.openBox(AppConstants.boxUser);
      await Hive.openBox(AppConstants.boxActivities);
      await Hive.openBox(AppConstants.boxBuildings);
      await Hive.openBox(AppConstants.boxStocks);
      await Hive.openBox(AppConstants.boxSales);
      await Hive.openBox(AppConstants.boxClients);
      await Hive.openBox(AppConstants.boxSync);
    } catch (e, stackTrace) {
      AppLogger.error('Error opening Hive boxes', e, stackTrace);
    }
  }

  static Box<T> getBox<T>(String boxName) {
    return Hive.box<T>(boxName);
  }

  static Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
    } catch (e, stackTrace) {
      AppLogger.error('Error closing Hive boxes', e, stackTrace);
    }
  }
}
