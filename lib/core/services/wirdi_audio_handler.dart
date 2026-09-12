import 'package:audio_service/audio_service.dart';

import 'quran_audio_service.dart';
import 'radio_service.dart';

/// Bridges Wirdi's existing Radio + Quran audio playback into the
/// OS-level media session: lock-screen controls and the persistent
/// notification-shade "now playing" card with Play/Pause/Stop.
///
/// This does NOT own audio playback itself -- RadioService and
/// QuranAudioService remain the single source of truth for what's
/// actually playing. This handler only listens to them (they're already
/// ChangeNotifiers) and mirrors their state into the system media
/// session, and forwards system button taps back into whichever service
/// is currently active.
class WirdiAudioHandler extends BaseAudioHandler {
  WirdiAudioHandler() {
    RadioService.instance.addListener(_onRadioChanged);
    quranAudio.addListener(_onQuranChanged);
    _publishIdle();
  }

  bool get _radioActive => RadioService.instance.currentStation != null;
  bool get _quranActive => quranAudio.playingAyah != null;

  void _onRadioChanged() {
    if (_radioActive) {
      _publishRadioState();
    } else if (!_quranActive) {
      _publishIdle();
    }
  }

  void _onQuranChanged() {
    if (_quranActive) {
      _publishQuranState();
    } else if (!_radioActive) {
      _publishIdle();
    }
  }

  void _publishRadioState() {
    final r = RadioService.instance;
    final station = r.currentStation;
    if (station == null) return;

    mediaItem.add(MediaItem(
      id: 'radio_${station.id}',
      title: station.nameEn.isNotEmpty ? station.nameEn : station.nameAr,
      artist: 'Wirdi Radio',
      album: r.sourceLabel,
    ));

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.stop,
        r.isPlaying ? MediaControl.pause : MediaControl.play,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: r.isLoading
          ? AudioProcessingState.loading
          : AudioProcessingState.ready,
      playing: r.isPlaying,
    ));
  }

  void _publishQuranState() {
    final q = quranAudio;
    final ayah = q.playingAyah;
    if (ayah == null) return;

    mediaItem.add(MediaItem(
      id: 'quran_ayah_$ayah',
      title: q.playingWholeSurah ? 'Reciting Surah -- Ayah $ayah' : 'Ayah $ayah',
      artist: 'Wirdi -- Quran Recitation',
    ));

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.stop,
        q.isPaused ? MediaControl.play : MediaControl.pause,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: q.isBuffering
          ? AudioProcessingState.loading
          : AudioProcessingState.ready,
      playing: !q.isPaused,
    ));
  }

  void _publishIdle() {
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      controls: const [],
      systemActions: const {},
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  @override
  Future<void> play() async {
    if (_radioActive) {
      final station = RadioService.instance.currentStation;
      if (station != null) await RadioService.instance.play(station);
    } else if (_quranActive) {
      await quranAudio.resume();
    }
  }

  @override
  Future<void> pause() async {
    if (_radioActive) {
      await RadioService.instance.pause();
    } else if (_quranActive) {
      await quranAudio.pause();
    }
  }

  @override
  Future<void> stop() async {
    await RadioService.instance.stop();
    await quranAudio.stop();
    await super.stop();
  }
}

/// Set once in main() right after AudioService.init(). Nothing else needs
/// to reach into this directly during normal use -- Radio and Quran
/// screens keep talking to their own services exactly as before -- but
/// it's exposed for completeness.
late WirdiAudioHandler wirdiAudioHandler;

/// Set if AudioService.init() failed in main() -- previously this was
/// only ever written to debugPrint, which nobody watching the running
/// app could ever see. Exposed so the UI can surface it directly.
String? audioServiceInitError;
