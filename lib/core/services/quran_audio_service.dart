import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/app_sources.dart';
import '../models/quran_models.dart';
import 'app_logger.dart';
import 'audio_download_service.dart';
import 'playback_coordinator.dart';
import 'settings_service.dart';

/// App-wide Quran audio playback, deliberately NOT owned by any single
/// screen's State — a screen-owned player is destroyed the moment the
/// user navigates away (e.g. switching bottom-nav tabs), which used to
/// stop playback. Living here means playback survives navigation, and
/// both the Surah reader and the Mushaf page view can control/observe
/// the exact same playback session.
///
/// Uses two alternating players for gapless "play whole surah": while
/// one ayah plays, the next is silently preloaded into the other, so
/// advancing doesn't need to wait for a fresh network fetch.
class QuranAudioService extends ChangeNotifier {
  QuranAudioService._();
  static final QuranAudioService instance = QuranAudioService._();

  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();
  late AudioPlayer _active;
  late AudioPlayer _standby;
  bool _initialized = false;

  int? _surahNumber;
  int _surahAyahOffset = 0;
  int _totalAyahsInSurah = 0;
  int? _rangeStartAyah;
  int? _rangeEndAyah;

  int? playingAyah;
  bool playingWholeSurah = false;
  bool repeatCurrent = false;
  int? repeatCreditsRemaining;
  bool isBuffering = false;
  bool isPaused = false;
  double playbackRate = 1.0;
  bool repeatSurah = false;

  /// Which ayah number (if any) has been successfully preloaded into
  /// [_standby], confirmed by a completed (non-erroring) setSourceUrl
  /// call. Null means "nothing confirmed ready" -- either preload hasn't
  /// finished yet, failed, or wasn't needed (local file). [_advanceSequential]
  /// only tries to resume [_standby] when this matches the ayah it's
  /// advancing to; otherwise it falls back to a normal fresh fetch.
  int? _preloadedAyah;

  /// The surah currently loaded for playback, or null if nothing is
  /// playing. Exposed for UI (e.g. a global mini-player) that needs to
  /// display what's playing without already knowing the surah number.
  int? get currentSurahNumber => _surahNumber;

  bool isPlayingFor(int surahNumber, int ayahNumber) =>
      _surahNumber == surahNumber && playingAyah == ayahNumber;

  bool isSurahActive(int surahNumber) => _surahNumber == surahNumber;

  void _ensureInit() {
    if (_initialized) return;
    _active = _playerA;
    _standby = _playerB;

    // Capture the concrete player objects in local variables so each
    // listener always reports which physical player actually fired the
    // event — using the mutable _active/_standby fields here directly
    // would be wrong, since they get swapped during playback and the
    // closures would then misreport which one completed.
    final playerA = _playerA;
    final playerB = _playerB;
    playerA.onPlayerComplete.listen((_) => _handleComplete(playerA));
    playerB.onPlayerComplete.listen((_) => _handleComplete(playerB));

    _initialized = true;
  }

  void _loadSurahContext(SurahModel surah, List<SurahModel> allSurahs) {
    _surahNumber = surah.number;
    _totalAyahsInSurah = surah.ayahs.length;
    _surahAyahOffset = allSurahs
        .where((s) => s.number < surah.number)
        .fold(0, (sum, s) => sum + s.ayahs.length);
  }

  Future<void> playAyah(SurahModel surah, List<SurahModel> allSurahs, int ayahNumber, {bool keepRepeat = false}) async {
    await PlaybackCoordinator.stopRadioForQuran();
    _ensureInit();
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = false;
    isPaused = false;
    if (!keepRepeat) repeatCurrent = false;
    notifyListeners();
    await _playAyahAudio(ayahNumber);
  }

  Future<void> playWholeSurah(SurahModel surah, List<SurahModel> allSurahs) async {
    await PlaybackCoordinator.stopRadioForQuran();
    _ensureInit();
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = true;
    _rangeStartAyah = null;
    _rangeEndAyah = null;
    repeatCurrent = false;
    isPaused = false;
    notifyListeners();
    await _playAyahAudio(1);
    _preloadNext(2);
  }

  /// Plays ayahs [startAyah] through [endAyah] (inclusive) of [surah],
  /// then stops (or repeats the range if [repeatSurah] is enabled).
  /// Reuses the same sequential/preloading engine as [playWholeSurah],
  /// just bounded to the given range instead of the whole surah.
  Future<void> playRange(SurahModel surah, List<SurahModel> allSurahs, int startAyah, int endAyah) async {
    await PlaybackCoordinator.stopRadioForQuran();
    _ensureInit();
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = true;
    _rangeStartAyah = startAyah;
    _rangeEndAyah = endAyah;
    repeatCurrent = false;
    isPaused = false;
    notifyListeners();
    await _playAyahAudio(startAyah);
    _preloadNext(startAyah + 1);
  }

  /// Pauses playback in place (resumable), for the system media
  /// notification's Pause button. Distinct from [stop], which fully
  /// clears the "now playing" ayah.
  Future<void> pause() async {
    try {
      await _active.pause();
      isPaused = true;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Failed to pause ayah playback', error: e, stackTrace: st);
    }
  }

  /// Resumes playback after [pause], for the system media notification's
  /// Play button.
  Future<void> resume() async {
    try {
      await _active.resume();
      isPaused = false;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Failed to resume ayah playback', error: e, stackTrace: st);
    }
  }

  Future<void> _playAyahAudio(int ayahNumber) async {
    final globalNumber = _surahAyahOffset + ayahNumber;
    playingAyah = ayahNumber;
    isBuffering = true;
    notifyListeners();

    try {
      await _active.stop();
    } catch (_) {
      // Nothing loaded yet — expected on first play, safe to ignore.
    }

    try {
      final localPath = await AudioDownloadService.localPathFor(appSettings.reciterId, globalNumber);
      if (localPath != null) {
        await _active.play(DeviceFileSource(localPath));
      } else {
        await _active.play(UrlSource(AppSources.ayahAudioUrl(globalNumber, reciter: appSettings.reciterId)));
      }
      await _active.setPlaybackRate(playbackRate);
    } catch (e, st) {
      AppLogger.error('Ayah audio playback failed', error: e, stackTrace: st);
      playingAyah = null;
      playingWholeSurah = false;
    } finally {
      isBuffering = false;
      notifyListeners();
    }
  }

  Future<void> _preloadNext(int ayahNumber) async {
    _preloadedAyah = null;
    if (!playingWholeSurah) return;
    if (ayahNumber > (_rangeEndAyah ?? _totalAyahsInSurah)) return;
    final globalNumber = _surahAyahOffset + ayahNumber;

    final localPath = await AudioDownloadService.localPathFor(appSettings.reciterId, globalNumber);
    if (localPath != null) return; // already instant to play locally -- _advanceSequential will fresh-fetch it, which is cheap for local files

    try {
      await _standby.setSourceUrl(AppSources.ayahAudioUrl(globalNumber, reciter: appSettings.reciterId));
      _preloadedAyah = ayahNumber;
    } catch (e, st) {
      _preloadedAyah = null;
      AppLogger.error('Preload failed for ayah $ayahNumber -- will fetch fresh when reached instead of risking a silent stall', error: e, stackTrace: st);
    }
  }

  Future<void> _advanceSequential(int nextAyah) async {
    if (_preloadedAyah != nextAyah) {
      // Nothing confirmed ready in the standby player (preload failed,
      // hasn't finished, or was a local file) -- don't gamble on resuming
      // an empty player, which can silently produce no audio and no error.
      // A normal fresh fetch always either plays or reports a real error.
      await _playAyahAudio(nextAyah);
      _preloadNext(nextAyah + 1);
      return;
    }

    final previousActive = _active;
    _active = _standby;
    _standby = previousActive;
    _preloadedAyah = null;

    playingAyah = nextAyah;
    notifyListeners();

    try {
      await _active.resume();
    } catch (e, st) {
      AppLogger.error('Resuming preloaded ayah failed, falling back to fresh fetch', error: e, stackTrace: st);
      await _playAyahAudio(nextAyah);
      return;
    }

    _preloadNext(nextAyah + 1);
  }

  void _handleComplete(AudioPlayer source) {
    if (source != _active) return; // stray event from the preloading standby player

    if (repeatCurrent && playingAyah != null) {
      if (_consumeRepeatCredit()) {
        _playAyahAudio(playingAyah!);
        return;
      }
      repeatCurrent = false;
    }

    if (playingWholeSurah && playingAyah != null) {
      final nextAyah = playingAyah! + 1;
      final effectiveEnd = _rangeEndAyah ?? _totalAyahsInSurah;
      if (nextAyah <= effectiveEnd) {
        _advanceSequential(nextAyah);
        return;
      }
      if (repeatSurah) {
        final restartAt = _rangeStartAyah ?? 1;
        _playAyahAudio(restartAt);
        _preloadNext(restartAt + 1);
        return;
      }
    }

    playingAyah = null;
    playingWholeSurah = false;
    notifyListeners();
  }

  Future<void> stop() async {
    try {
      await _active.stop();
    } catch (_) {
      // Already stopped/nothing loaded — fine.
    }
    try {
      await _standby.stop();
    } catch (_) {
      // Nothing preloaded — fine.
    }
    playingAyah = null;
    playingWholeSurah = false;
    isPaused = false;
    _rangeStartAyah = null;
    _rangeEndAyah = null;
    notifyListeners();
  }

  void toggleRepeat() {
    repeatCurrent = !repeatCurrent;
    notifyListeners();
  }

  /// Sets playback speed (e.g. 0.5-2.0) for the current and future ayahs
  /// this session. Applied immediately if something is already playing.
  Future<void> setSpeed(double rate) async {
    playbackRate = rate;
    try {
      await _active.setPlaybackRate(rate);
    } catch (_) {
      // Nothing playing yet -- fine, applies on next play.
    }
    notifyListeners();
  }

  void toggleRepeatSurah() {
    repeatSurah = !repeatSurah;
    notifyListeners();
  }

  void setRepeatCount(int? count) {
    repeatCreditsRemaining = count;
    notifyListeners();
  }

  bool _consumeRepeatCredit() {
    if (repeatCreditsRemaining == null) return true;
    if (repeatCreditsRemaining! <= 0) return false;
    repeatCreditsRemaining = repeatCreditsRemaining! - 1;
    return true;
  }
}

/// Single app-wide instance — playback survives navigation between
/// screens because it isn't tied to any one screen's lifecycle.
final QuranAudioService quranAudio = QuranAudioService.instance;
