import 'package:flutter/material.dart';
import 'package:investorapp_eminates/core/services/update_service.dart';
import 'package:ota_update/ota_update.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Starting download...';
    });

    try {
      OtaUpdate()
          .execute(
        widget.updateInfo.downloadUrl,
        destinationFilename: 'eminates_update_v${widget.updateInfo.version}.apk',
      )
          .listen(
        (OtaEvent event) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Status: ${event.status.name}';
              if (event.value != null && event.value!.isNotEmpty) {
                 // Try parsing percentage
                 try {
                   _progress = double.parse(event.value!);
                   _statusMessage = 'Downloading: ${_progress.toStringAsFixed(0)}%';
                 } catch (_) {}
              }
              
              if (event.status == OtaStatus.INSTALLING) {
                 _statusMessage = 'Installing...';
                 _isDownloading = false;
              } else if (event.status == OtaStatus.DOWNLOAD_ERROR || event.status == OtaStatus.INTERNAL_ERROR) {
                 _statusMessage = 'Error: ${event.value}';
                 _isDownloading = false;
              }
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Download failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.updateInfo.forceUpdate,
      child: AlertDialog(
        title: Text('New Update Available', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${widget.updateInfo.version}-${widget.updateInfo.buildNumber}) is available.',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.updateInfo.description != null) ...[
              const SizedBox(height: 12),
              const Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.updateInfo.description!),
            ],
            const SizedBox(height: 20),
            if (_isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress / 100),
                  const SizedBox(height: 8),
                  Text(_statusMessage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            else if (_statusMessage.startsWith('Download failed'))
               Text(_statusMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          if (!widget.updateInfo.forceUpdate && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          FilledButton.icon(
            onPressed: _isDownloading ? null : _startDownload,
            icon: const Icon(Icons.system_update_alt),
            label: Text(_isDownloading ? 'Downloading...' : 'Update Now'),
          ),
        ],
      ),
    );
  }
}
