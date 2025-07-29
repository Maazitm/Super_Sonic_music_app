
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<FileSystemEntity> _audioFiles = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _permissionGranted = false;
  bool _isLoading = true;
  String _statusMessage = '';
  bool _isShuffled = false;
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _checkPermissions();
  }

  Future<void> _initAudioPlayer() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      
      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
        });
        
        if (state.processingState == ProcessingState.completed) {
          if (_isRepeating) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.play();
          } else {
            _playNext();
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });

    try {
      bool permissionGranted = false;
      
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        // Request multiple permissions for better compatibility
        Map<Permission, PermissionStatus> permissions = {};
        
        if (sdkInt >= 33) {
          // Android 13+
          permissions = await [
            Permission.audio,
            Permission.manageExternalStorage,
            Permission.storage,
          ].request();
        } else if (sdkInt >= 30) {
          // Android 11-12
          permissions = await [
            Permission.manageExternalStorage,
            Permission.storage,
          ].request();
        } else {
          // Android 10 and below
          permissions = await [
            Permission.storage,
          ].request();
        }
        
        // Check if any permission is granted
        permissionGranted = permissions.values.any((status) => status.isGranted);
      } else {
        // iOS
        final mediaPermission = await Permission.mediaLibrary.request();
        permissionGranted = mediaPermission.isGranted;
      }

      setState(() {
        _permissionGranted = permissionGranted;
        _statusMessage = permissionGranted 
            ? 'Permission granted, scanning files...' 
            : 'Permission denied';
      });

      if (permissionGranted) {
        await _scanAudioFiles();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking permissions: $e';
      });
      debugPrint('Permission error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAudioFiles() async {
    setState(() {
      _isLoading = true;
      _audioFiles = [];
      _statusMessage = 'Scanning for audio files...';
    });

    try {
      final List<FileSystemEntity> allAudioFiles = [];
      
      // Comprehensive list of audio file extensions
      final audioExtensions = [
        '.mp3', 
       // '.m4a', 
        //'.wav', '.ogg', '.aac', '.flac', 
       // '.wma', '.opus', '.3gp', '.amr', 
       '.mp4',
       '.webm'
      ];
      
      if (Platform.isAndroid) {
        // Comprehensive directory scanning for Android
        final directories = <String>[
          '/storage/emulated/0',
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/Podcasts',
          '/storage/emulated/0/Ringtones',
          '/storage/emulated/0/Notifications',
          '/storage/emulated/0/Alarms',
          '/storage/emulated/0/Android/data',
          '/storage/emulated/0/Android/media',
          '/sdcard',
          '/sdcard/Music',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        // Add external storage directories
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directories.add(externalDir.path);
            directories.add('${externalDir.parent.path}/Music');
            directories.add('${externalDir.parent.path}/Download');
          }
        } catch (e) {
          debugPrint('Could not get external storage directory: $e');
        }

        // Add all external storage directories
        try {
          final List<Directory> externalDirs = await getExternalStorageDirectories() ?? [];
          for (final dir in externalDirs) {
            directories.add(dir.path);
            directories.add('${dir.parent.path}/Music');
            directories.add('${dir.parent.path}/Download');
          }
        } catch (e) {
          debugPrint('Error getting external directories: $e');
        }

        // Scan each directory
        for (final dirPath in directories) {
          final dir = Directory(dirPath);
          try {
            if (await dir.exists()) {
              debugPrint('Scanning directory: $dirPath');
              final files = await _findAudioFiles(dir, audioExtensions);
              allAudioFiles.addAll(files);
              setState(() {
                _statusMessage = 'Found ${allAudioFiles.length} audio files...';
              });
            }
          } catch (e) {
            debugPrint('Error scanning directory $dirPath: $e');
          }
        }
        
        // Additional scan for root storage
        try {
          final rootDir = Directory('/storage');
          if (await rootDir.exists()) {
            await for (final entity in rootDir.list()) {
              if (entity is Directory) {
                try {
                  final files = await _findAudioFiles(entity, audioExtensions);
                  allAudioFiles.addAll(files);
                } catch (e) {
                  debugPrint('Error scanning ${entity.path}: $e');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error scanning root storage: $e');
        }
      } else {
        // iOS scanning
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final files = await _findAudioFiles(appDocDir, audioExtensions);
          allAudioFiles.addAll(files);
        } catch (e) {
          debugPrint('Error scanning iOS directories: $e');
        }
      }

      // Remove duplicates and sort
      final uniqueFiles = <String, FileSystemEntity>{};
      for (final file in allAudioFiles) {
        uniqueFiles[file.path] = file;
      }
      
      final sortedFiles = uniqueFiles.values.toList();
      sortedFiles.sort((a, b) => path.basename(a.path).toLowerCase()
          .compareTo(path.basename(b.path).toLowerCase()));

      setState(() {
        _audioFiles = sortedFiles;
        _statusMessage = 'Found ${_audioFiles.length} audio files';
      });

      if (_audioFiles.isNotEmpty) {
        await _loadAudio(_audioFiles.first.path);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error scanning files: $e';
      });
      debugPrint('Scan error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<FileSystemEntity>> _findAudioFiles(
      Directory directory, List<String> extensions) async {
    final List<FileSystemEntity> audioFiles = [];
    
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true, followLinks: false)) {
          try {
            if (entity is File) {
              final ext = path.extension(entity.path).toLowerCase();
              if (extensions.contains(ext)) {
                // Verify file exists and is readable
                final stat = await entity.stat();
                if (stat.size > 0) {
                  audioFiles.add(entity);
                  debugPrint('Found audio file: ${entity.path}');
                }
              }
            }
          } catch (e) {
            // Skip files that can't be accessed
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error accessing directory ${directory.path}: $e');
    }
    
    return audioFiles;
  }

  Future<void> _loadAudio(String filePath) async {
    try {
      setState(() {
        _statusMessage = 'Loading: ${path.basename(filePath)}';
      });
      
      await _audioPlayer.setFilePath(filePath);
      
      setState(() {
        _statusMessage = 'Ready to play: ${path.basename(filePath)}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading audio: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playAudio() async {
    try {
      if (_audioFiles.isEmpty) return;
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> _playNext() async {
    if (_audioFiles.isEmpty) return;
    
    setState(() {
      if (_isShuffled) {
        _currentIndex = (_currentIndex + 1 + DateTime.now().millisecond) % _audioFiles.length;
      } else {
        _currentIndex = (_currentIndex + 1) % _audioFiles.length;
      }
    });
    
    await _loadAudio(_audioFiles[_currentIndex].path);
    if (_isPlaying) {
      await _playAudio();
    }
  }

  Future<void> _playPrevious() async {
    if (_audioFiles.isEmpty) return;
    
    setState(() {
      _currentIndex = (_currentIndex - 1 + _audioFiles.length) % _audioFiles.length;
    });
    
    await _loadAudio(_audioFiles[_currentIndex].path);
    if (_isPlaying) {
      await _playAudio();
    }
  }

  Future<void> _playSelected(int index) async {
    if (index < 0 || index >= _audioFiles.length) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    await _loadAudio(_audioFiles[index].path);
    await _playAudio();
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeating = !_isRepeating;
    });
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

  String _getArtistName(String fileName) {
    // Try to extract artist from filename (assuming format: Artist - Song.mp3)
    if (fileName.contains(' - ')) {
      return fileName.split(' - ').first;
    }
    return 'Unknown Artist';
  }

  String _getSongName(String fileName) {
    // Remove extension and try to extract song name
    String nameWithoutExt = path.basenameWithoutExtension(fileName);
    if (nameWithoutExt.contains(' - ')) {
      return nameWithoutExt.split(' - ').last;
    }
    return nameWithoutExt;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1DB954), Color(0xFF121212)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : !_permissionGranted
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1DB954), Color(0xFF121212)],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.music_off,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Storage Access Required',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'We need access to your device storage to find and play your music files.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _checkPermissions,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Grant Permission',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => openAppSettings(),
                            child: const Text(
                              'Open App Settings',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Custom App Bar
                    Container(
                      padding: const EdgeInsets.only(
                        top: 40,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1DB954).withOpacity(0.8),
                            const Color(0xFF121212),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'My Music',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _scanAudioFiles,
                          ),
                        ],
                      ),
                    ),

                    // Status message
                    if (_statusMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF1DB954).withOpacity(0.1),
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1DB954),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Music List
                    Expanded(
                      child: _audioFiles.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_music,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No Music Found',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Add some music files to your device and tap the refresh button',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: _scanAudioFiles,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Scan Again'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 200),
                              itemCount: _audioFiles.length,
                              itemBuilder: (context, index) {
                                final file = _audioFiles[index];
                                final fileName = path.basename(file.path);
                                final songName = _getSongName(fileName);
                                final artistName = _getArtistName(fileName);
                                final isCurrentFile = _currentIndex == index;
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrentFile 
                                        ? const Color(0xFF1DB954).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isCurrentFile 
                                            ? const Color(0xFF1DB954)
                                            : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isCurrentFile && _isPlaying
                                            ? Icons.equalizer
                                            : Icons.music_note,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      songName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isCurrentFile 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                        color: isCurrentFile 
                                            ? const Color(0xFF1DB954)
                                            : Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      artistName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isCurrentFile
                                        ? Icon(
                                            _isPlaying 
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_filled,
                                            color: const Color(0xFF1DB954),
                                            size: 32,
                                          )
                                        : Icon(
                                            Icons.play_circle_outline,
                                            color: Colors.grey[600],
                                            size: 32,
                                          ),
                                    onTap: () => _playSelected(index),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

      // Bottom Player
      bottomSheet: _audioFiles.isNotEmpty
          ? Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF121212),
                    const Color(0xFF1E1E1E),
                  ],
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
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: _audioPlayer.durationStream,
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
                                ),
                                child: Slider(
                                  value: duration.inMilliseconds > 0
                                      ? position.inMilliseconds.toDouble()
                                      : 0.0,
                                  min: 0,
                                  max: duration.inMilliseconds.toDouble(),
                                  onChanged: duration.inMilliseconds > 0
                                      ? (value) async {
                                          await _audioPlayer.seek(
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
                                  _getSongName(path.basename(_audioFiles[_currentIndex].path)),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getArtistName(path.basename(_audioFiles[_currentIndex].path)),
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
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color: _isShuffled 
                                      ? const Color(0xFF1DB954)
                                      : Colors.white70,
                                ),
                                onPressed: _toggleShuffle,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _audioFiles.length > 1 ? _playPrevious : null,
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1DB954),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: _isPlaying ? _pauseAudio : _playAudio,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _audioFiles.length > 1 ? _playNext : null,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.repeat,
                                  color: _isRepeating 
                                      ? const Color(0xFF1DB954)
                                      : Colors.white70,
                                ),
                                onPressed: _toggleRepeat,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
