import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/video_service.dart';


class AudioPlayerService {
final ValueNotifier<bool> isShuffledNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isRepeatingNotifier = ValueNotifier(false);
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<MediaFile> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  bool _isRepeating = false;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<MediaFile> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isShuffled => _isShuffled;
  bool get isRepeating => _isRepeating;
  MediaFile? get currentTrack => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  Future<void> initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_isRepeating) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.play();
          } else {
            playNext();
          }
        }
      });
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  Future<void> setPlaylist(List<MediaFile> audioFiles, {int startIndex = 0}) async {
    _playlist = audioFiles.where((file) => file.type == MediaType.audio).toList();
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    
    if (_playlist.isNotEmpty) {
      await loadTrack(_currentIndex);
    }
  }

  Future<void> loadTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    try {
      _currentIndex = index;
      await _audioPlayer.setFilePath(_playlist[index].path);
    } catch (e) {
      print('Error loading track: $e');
      throw Exception('Error loading audio: $e');
    }
  }

  Future<void> play() async {
    try {
      if (_playlist.isEmpty) return;
      await VideoService().pause();
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
      throw Exception('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    
    int nextIndex;
    if (_isShuffled) {
      nextIndex = (_currentIndex + 1 + DateTime.now().millisecond) % _playlist.length;
    } else {
      nextIndex = (_currentIndex + 1) % _playlist.length;
    }
    
    await loadTrack(nextIndex);
    if (_audioPlayer.playing) {
      await play();
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    final previousIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await loadTrack(previousIndex);
    if (_audioPlayer.playing) {
      await play();
    }
  }

  Future<void> playTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    await loadTrack(index);
    await play();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
     isShuffledNotifier.value = !isShuffledNotifier.value;
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
     isRepeatingNotifier.value = !isRepeatingNotifier.value;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
