import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_sources.dart';
import '../models/quran_models.dart';
import 'app_logger.dart';
import 'local_cache_service.dart';

/// Offline-first repository for the Quran text.
///
/// Strategy: if a cached copy exists, return it immediately (fast, works
/// with no connection) and refresh from network in the background so the
/// next launch has fresh data. If there is no cache yet, fetch from
/// network and cache the result. If the network fetch fails and there is
/// no cache, the error is rethrown so the UI can show a real error state.
class QuranRepository {
  static Future<Map<String, dynamic>?> getSurahSummary(int surahNumber) async {
    final summaries = {
      1: {'name': 'Al-Fatiha', 'verses': 7, 'type': 'Meccan', 'theme': 'Opening chapter'},
      2: {'name': 'Al-Baqarah', 'verses': 286, 'type': 'Medinan', 'theme': 'The Cow'},
      3: {'name': 'Aal-i-Imran', 'verses': 200, 'type': 'Medinan', 'theme': 'Family of Imran'},
    };
    return summaries[surahNumber];
  }
  static Future<Map<String, dynamic>?> getLastReadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_read_position');
    return raw != null ? jsonDecode(raw) as Map<String, dynamic> : null;
  }
  
  static Future<void> saveLastReadPosition(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final position = {
      'surah': surah,
      'ayah': ayah,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('last_read_position', jsonEncode(position));
  }
  QuranRepository._();

  static const String _cacheKey = 'cache_quran_json_v1';

  static Future<List<SurahModel>> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await LocalCacheService.getString(_cacheKey);
      if (cached != null) {
        // Return cached data immediately, refresh silently in background.
        // ignore: unawaited_futures
        _refreshInBackground();
        return _parse(cached);
      }
    }

    try {
      final raw = await _fetchRaw();
      await LocalCacheService.setString(_cacheKey, raw);
      return _parse(raw);
    } catch (e, st) {
      final cached = await LocalCacheService.getString(_cacheKey);
      if (cached != null) {
        AppLogger.error('Quran fetch failed, falling back to cache', error: e, stackTrace: st);
        return _parse(cached);
      }
      AppLogger.error('Quran fetch failed with no cache available', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<void> _refreshInBackground() async {
    try {
      final raw = await _fetchRaw();
      await LocalCacheService.setString(_cacheKey, raw);
    } catch (e, st) {
      AppLogger.error('Quran background refresh failed, serving cached copy', error: e, stackTrace: st);
    }
  }

  static Future<String> _fetchRaw() async {
    final response = await http
        .get(Uri.parse(AppSources.quranJsonUrl))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Quran (HTTP ${response.statusCode})');
    }

    // Explicitly decode as UTF-8 — response.body defaults to
    // Latin-1 when a server doesn't declare charset=utf-8, which
    // mangles Arabic text into unreadable symbols.
    return utf8.decode(response.bodyBytes);
  }

  static Future<DateTime?> cachedAt() => LocalCacheService.getCachedAt(_cacheKey);

  static List<SurahModel> _parse(String raw) {
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw Exception('Unexpected Quran JSON format');
    }

    return decoded.map<SurahModel>((item) {
      final map = item as Map<String, dynamic>;
      final versesRaw = (map['verses'] as List<dynamic>? ?? []);

      final ayahs = versesRaw.map<AyahModel>((verse) {
        final verseMap = verse as Map<String, dynamic>;
        return AyahModel(
          number: _readInt(verseMap, ['id', 'number']),
          text: _readString(verseMap, ['text']),
        );
      }).toList();

      return SurahModel(
        number: _readInt(map, ['id', 'number']),
        name: _readString(map, ['name']),
        englishName: _readString(map, ['transliteration']),
        ayahs: ayahs,
      );
    }).toList();
  }

  static int _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value.toString();
    }
    return '';
  }
}
