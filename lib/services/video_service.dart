import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/audio_player_service.dart';


class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<MediaFile> _videoPlaylist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  MediaFile? _currentVideo;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<MediaFile> get videoPlaylist => _videoPlaylist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  MediaFile? get currentVideo => _currentVideo;

  Future<void> initialize() async {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> setVideoPlaylist(List<MediaFile> videoFiles, {int startIndex = 0}) async {
    _videoPlaylist = videoFiles.where((file) => file.type == MediaType.video).toList();
    _currentIndex = startIndex.clamp(0, _videoPlaylist.length - 1);
    
    if (_videoPlaylist.isNotEmpty) {
      await loadVideo(_currentIndex);
    }
  }

  Future<void> loadVideo(int index) async {
    if (index < 0 || index >= _videoPlaylist.length) return;
    
    try {
      _currentIndex = index;
      _currentVideo = _videoPlaylist[index];
      
      // Load the video file as audio (extract audio track)
      await _audioPlayer.setFilePath(_videoPlaylist[index].path);
    } catch (e) {
      print('Error loading video audio: $e');
      throw Exception('Error loading video audio: $e');
    }
  }

  Future<void> play() async {
    try {
      if (_videoPlaylist.isEmpty) return;
        await AudioPlayerService().pause();
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing video audio: $e');
      throw Exception('Error playing video audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing video audio: $e');
    }
  }

  Future<void> playNext() async {
    if (_videoPlaylist.isEmpty) return;
    
    final nextIndex = (_currentIndex + 1) % _videoPlaylist.length;
    await loadVideo(nextIndex);
    if (_isPlaying) {
      await play();
    }
  }

  Future<void> playPrevious() async {
    if (_videoPlaylist.isEmpty) return;
    
    final previousIndex = (_currentIndex - 1 + _videoPlaylist.length) % _videoPlaylist.length;
    await loadVideo(previousIndex);
    
    if (_isPlaying) {
      await play();
    }
  }

  Future<void> playVideo(int index) async {
    if (index < 0 || index >= _videoPlaylist.length) return;
    
    await loadVideo(index);
    await play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
