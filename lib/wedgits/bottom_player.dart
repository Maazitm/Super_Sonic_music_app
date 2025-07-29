import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../utils/theme.dart';
import 'package:path/path.dart' as path;

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();

    return StreamBuilder<PlayerState>(
      stream: audioService.audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final currentTrack = audioService.currentTrack;
        if (currentTrack == null) return const SizedBox.shrink();

        return Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.darkBackground, AppTheme.cardBackground],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress Bar
              StreamBuilder<Duration>(
                stream: audioService.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: audioService.audioPlayer.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              activeTrackColor: AppTheme.primaryGreen,
                              inactiveTrackColor: Colors.grey[600],
                              thumbColor: AppTheme.primaryGreen,
                            ),
                            child: Slider(
                              value:
                                  duration.inMilliseconds > 0
                                      ? position.inMilliseconds.toDouble()
                                      : 0.0,
                              min: 0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged:
                                  duration.inMilliseconds > 0
                                      ? (value) async {
                                        await audioService.seek(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      }
                                      : null,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // Song Info and Controls
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Song Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentTrack.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack.artist,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Control Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                         ValueListenableBuilder<bool>(
  valueListenable: audioService.isShuffledNotifier,
  builder: (_, isShuffled, __) => IconButton(
    icon: Icon(
      Icons.shuffle,
      color: isShuffled ? AppTheme.primaryGreen : Colors.white70,
    ),
    onPressed: () {
      audioService.toggleShuffle();
    },
  ),
),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed:
                                audioService.playlist.length > 1
                                    ? () => audioService.playPrevious()
                                    : null,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                (snapshot.data?.playing ?? false)
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () {
                                if (snapshot.data?.playing ?? false) {
                                  audioService.pause();
                                } else {
                                  audioService.play();
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed:
                                audioService.playlist.length > 1
                                    ? () => audioService.playNext()
                                    : null,
                          ),
                          ValueListenableBuilder<bool>(
  valueListenable: audioService.isRepeatingNotifier,
  builder: (_, isRepeating, __) => IconButton(
    icon: Icon(
      Icons.repeat,
      color: isRepeating ? AppTheme.primaryGreen : Colors.white70,
    ),
    onPressed: () {
      audioService.toggleRepeat();
    },
  ),
),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
