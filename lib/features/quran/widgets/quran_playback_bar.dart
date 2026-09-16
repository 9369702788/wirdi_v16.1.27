import 'package:flutter/material.dart';
import '../../../core/services/quran_audio_service.dart';
import '../../../core/theme/app_theme.dart';

class QuranPlaybackBar extends StatelessWidget {
  const QuranPlaybackBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: quranAudio,
      builder: (context, _) {
        if (quranAudio.playingAyah == null) return const SizedBox.shrink();
        final position = quranAudio.position;
        final duration = quranAudio.duration;
        final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
        final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        return Material(
          elevation: 10,
          color: AppColors.primaryEmerald,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: value,
                  min: 0,
                  max: max,
                  onChanged: duration.inMilliseconds > 0 ? (v) => quranAudio.seek(Duration(milliseconds: v.round())) : null,
                  activeColor: AppColors.goldAccent,
                  inactiveColor: Colors.white24,
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr ? 'سورة ${quranAudio.currentSurahNumber ?? '-'} • آية ${quranAudio.playingAyah ?? '-'}' : 'Surah ${quranAudio.currentSurahNumber ?? '-'} • Ayah ${quranAudio.playingAyah ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: quranAudio.isPaused ? (isAr ? 'استكمال' : 'Resume') : (isAr ? 'إيقاف مؤقت' : 'Pause'),
                      icon: Icon(quranAudio.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white),
                      onPressed: () => quranAudio.isPaused ? quranAudio.resume() : quranAudio.pause(),
                    ),
                    IconButton(
                      tooltip: isAr ? 'إيقاف' : 'Stop',
                      icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                      onPressed: quranAudio.stop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
