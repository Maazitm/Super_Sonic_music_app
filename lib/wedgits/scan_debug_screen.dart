import 'package:flutter/material.dart';
import 'package:super_sonic/modal/media_file.dart';
import 'package:super_sonic/services/enchanced_media_scanner.dart';
import '../utils/theme.dart';

class ScanDebugDialog extends StatefulWidget {
  const ScanDebugDialog({super.key});

  @override
  State<ScanDebugDialog> createState() => _ScanDebugDialogState();
}

class _ScanDebugDialogState extends State<ScanDebugDialog> {
  bool _isScanning = false;
  String _statusMessage = '';
  List<MediaFile> _foundFiles = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: const Text(
        'Debug Scanner',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            if (_isScanning)
              Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _startDebugScan,
                    child: const Text('Start Debug Scan'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Found ${_foundFiles.length} files',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _foundFiles.length,
                itemBuilder: (context, index) {
                  final file = _foundFiles[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      file.type == MediaType.audio ? Icons.music_note : Icons.videocam,
                      color: file.type == MediaType.audio ? AppTheme.primaryGreen : Colors.red,
                      size: 20,
                    ),
                    title: Text(
                      file.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      file.path,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  Future<void> _startDebugScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Starting debug scan...';
      _foundFiles.clear();
    });

    try {
      final files = await EnhancedMediaScanner.comprehensiveScan(
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = status;
          });
        },
      );

      setState(() {
        _foundFiles = files;
        _isScanning = false;
        _statusMessage = 'Scan complete!';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error: $e';
      });
    }
  }
}
