import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final bool forceUpdate;
  final String? description;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.forceUpdate,
    this.description,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      downloadUrl: json['download_url'] as String,
      forceUpdate: json['force_update'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }
}

class UpdateService {
  final SupabaseClient _supabase;

  UpdateService(this._supabase);

  Future<UpdateInfo?> checkForUpdate() async {
    print('UpdateService: checkForUpdate called.');
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      print('UpdateService: Local Version: ${packageInfo.version}, Build: ${packageInfo.buildNumber}');
      
      var currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      // Handle split-per-abi version codes (e.g., 1003, 2003)
      // Flutter default split logic typically multiplies version by 1000 + arch code.
      // We normalize this back to the base build number for comparison.
      if (currentBuildNumber >= 1000) {
        currentBuildNumber = currentBuildNumber ~/ 1000;
        print('UpdateService: Detected split-abi build. Normalized to: $currentBuildNumber');
      }
      
      final platform = Platform.isAndroid ? 'android' : 'ios';
      print('UpdateService: Checking updates for platform: $platform');

      // Fetch latest version for this platform
      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('UpdateService: No update records found in Supabase.');
        return null;
      }

      final latestVersion = UpdateInfo.fromJson(response);
      print('UpdateService: Remote Version: ${latestVersion.version}, Local Version: ${packageInfo.version}');

      if (_isNewerVersion(latestVersion.version, packageInfo.version)) {
        print('UpdateService: Update available (Version mismatch)!');
        return latestVersion;
      }
      
      print('UpdateService: No update needed.');
      return null;
    } catch (e) {
      print('UpdateService: Error checking for updates: $e');
      return null;
    }
  }

  bool _isNewerVersion(String remote, String local) {
    try {
      final remoteParts = remote.split('.').map(int.parse).toList();
      final localParts = local.split('.').map(int.parse).toList();
      
      // Compare Major
      if (remoteParts[0] > localParts[0]) return true;
      if (remoteParts[0] < localParts[0]) return false;
      
      // Compare Minor
      if (remoteParts.length > 1 && localParts.length > 1) {
         if (remoteParts[1] > localParts[1]) return true;
         if (remoteParts[1] < localParts[1]) return false;
      }

      // Compare Patch
      if (remoteParts.length > 2 && localParts.length > 2) {
         if (remoteParts[2] > localParts[2]) return true;
         if (remoteParts[2] < localParts[2]) return false;
      }
      
      return false;
    } catch (e) {
       print('Error parsing versions: $e');
       return false;
    }
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(Supabase.instance.client);
});
