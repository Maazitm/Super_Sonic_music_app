import 'package:flutter/material.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/audio_player_service.dart';
import 'package:super_sonic/services/enchanced_media_scanner.dart';
import 'package:super_sonic/services/video_service.dart';
import 'package:super_sonic/view/library_screen.dart';
import 'package:super_sonic/view/loading_screen.dart';
import 'package:super_sonic/view/music_screen.dart';
import 'package:super_sonic/view/permission_screen.dart';
import 'package:super_sonic/view/video_screen.dart';
import 'package:super_sonic/wedgits/bottom_player.dart';
import 'package:super_sonic/wedgits/custom_buttom_navigation.dart';
import '../services/media_scanner_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MediaScannerService _scannerService = MediaScannerService();
  final AudioPlayerService _audioService = AudioPlayerService();
  final VideoService _videoService = VideoService();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _permissionGranted = false;
  String _statusMessage = '';
  List<MediaFile> _allMediaFiles = [];
  List<MediaFile> _audioFiles = [];
  List<MediaFile> _videoFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _audioService.initialize();
    await _videoService.initialize();
    await _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });

    try {
      final permissionGranted = await _scannerService.requestPermissions();

      setState(() {
        _permissionGranted = permissionGranted;
        _statusMessage =
            permissionGranted
                ? 'Permission granted, scanning files...'
                : 'Permission denied';
      });

      if (permissionGranted) {
        await _scanMediaFiles();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanMediaFiles() async {
    try {
      // Use enhanced scanner for more comprehensive results
      final mediaFiles = await EnhancedMediaScanner.comprehensiveScan(
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = status;
          });
        },
        onProgress: (current, total) {
          setState(() {
            _statusMessage = 'Scanning... ($current/$total)';
          });
        },
      );
      final audioFiles =
          {
            for (var file in mediaFiles.where(
              (file) => file.type == MediaType.audio,
            ))
              file.name: file,
          }.values.toList();

      final videoFiles =
          mediaFiles
              .where((file) => file.type == MediaType.video)
              .toList()
              .fold<Map<String, MediaFile>>({}, (map, file) {
                map[file.name] = file;
                return map;
              })
              .values
              .toList();

      setState(() {
        _allMediaFiles = mediaFiles;
        _audioFiles = audioFiles;
        _videoFiles = videoFiles;
        _statusMessage =
            'Found ${audioFiles.length} audio files and ${videoFiles.length} video files';
      });

      // Set up audio player with audio files
      if (audioFiles.isNotEmpty) {
        await _audioService.setPlaylist(audioFiles);
      }

      // Set up video service with video files
      if (videoFiles.isNotEmpty) {
        await _videoService.setVideoPlaylist(videoFiles);
      }

      // Log file locations for debugging
      print('=== AUDIO FILES FOUND ===');
      for (final file in audioFiles.take(10)) {
        print('${file.displayName} - ${file.path}');
      }
      if (audioFiles.length > 10) {
        print('... and ${audioFiles.length - 10} more audio files');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error scanning files: $e';
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _videoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(statusMessage: _statusMessage);
    }

    if (!_permissionGranted) {
      return PermissionScreen(onRetry: _checkPermissionsAndScan);
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                MusicScreen(
                  audioFiles: _audioFiles,
                  onRefresh: _scanMediaFiles,
                  statusMessage: _statusMessage,
                ),
                VideoScreen(
                  videoFiles: _videoFiles,
                  onRefresh: _scanMediaFiles,
                  statusMessage: _statusMessage,
                ),
                LibraryScreen(
                  audioFiles: _audioFiles,
                  videoFiles: _videoFiles,
                  onRefresh: _scanMediaFiles,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom Player (only show when audio is available and Music tab is selected)
          if (_audioFiles.isNotEmpty && _selectedIndex == 0)
            const BottomPlayer(),

          // Custom Bottom Navigation
          CustomBottomNavigation(
            selectedIndex: _selectedIndex,
            onTabSelected: _onTabSelected,
          ),
        ],
      ),
    );
  }
}
