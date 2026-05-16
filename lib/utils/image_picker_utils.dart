import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/image_source_sheet.dart';

enum MediaType { image, video }

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickMedia(
    BuildContext context, {
    MediaType mediaType = MediaType.image,
    double maxSizeMb = 2.0,
    Duration? maxVideoDuration,
  }) async {
    final effectiveMaxMb = mediaType == MediaType.image
        ? maxSizeMb
        : maxSizeMb.clamp(6.0, 60.0).toDouble();

    if (mediaType == MediaType.video && effectiveMaxMb != maxSizeMb) {
      log('Auto-adjusted video max size from $maxSizeMb → $effectiveMaxMb MB');
    }

    final ImageSourceType? sourceType =
        await showModalBottomSheet<ImageSourceType>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => ImageSourceSheet(mediaType: mediaType),
        );

    if (sourceType == null) return null;

    final ImageSource source = sourceType == ImageSourceType.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    XFile? pickedFile;

    if (mediaType == MediaType.image) {
      pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // ← slightly lower is usually enough
      );
    } else {
      pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: maxVideoDuration,
      );
    }

    if (pickedFile == null) return null;

    final originalPath = pickedFile.path;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: mediaType == MediaType.image
                ? const CustomLoadingIndicator(size: 60)
                : const _VideoProgressDialog(),
          ),
        ),
      );
    }

    String? resultPath;
    if (mediaType == MediaType.image) {
      resultPath = await _compressImage(originalPath, effectiveMaxMb);
    } else {
      resultPath = await _compressVideo(originalPath, effectiveMaxMb);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    return resultPath;
  }

  static Future<String?> _compressImage(String path, double maxSizeMb) async {
    final file = File(path);
    final bytes = await file.length();
    final sizeMb = bytes / (1024.0 * 1024.0);

    if (sizeMb <= maxSizeMb) {
      log('Image already ≤ ${maxSizeMb}MB → $sizeMb MB');
      return path;
    }

    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

    int quality = 92;
    XFile? result;

    while (quality >= 30) {
      result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
        numberOfRetries: 5,
      );

      if (result == null) break;

      final compBytes = await File(result.path).length();
      final compMb = compBytes / (1024.0 * 1024.0);

      log('Image quality $quality → ${compMb.toStringAsFixed(2)} MB');

      if (compMb <= maxSizeMb) {
        await file.delete();
        return result.path;
      }

      quality -= 12;
    }

    log('Image compression failed to reach ≤ ${maxSizeMb}MB → using original');
    return path;
  }

  static Future<String?> _compressVideo(String path, double maxSizeMb) async {
    final originalFile = File(path);
    final originalBytes = await originalFile.length();
    final originalMb = originalBytes / (1024.0 * 1024.0);

    log('Original video size: ${originalMb.toStringAsFixed(2)} MB');

    if (originalMb <= maxSizeMb) {
      log('Video already ≤ ${maxSizeMb}MB');
      return path;
    }

    await getTemporaryDirectory();

    final qualities = [
      VideoQuality.HighestQuality,
      VideoQuality.DefaultQuality,
      VideoQuality.MediumQuality,
      VideoQuality.LowQuality,
    ];

    MediaInfo? mediaInfo;

    for (final quality in qualities) {
      try {
        log('Trying video compression with $quality...');

        mediaInfo = await VideoCompress.compressVideo(
          path,
          quality: quality,
          deleteOrigin: false,
          frameRate: 30,
          includeAudio: true,
        );

        if (mediaInfo == null || mediaInfo.path == null) {
          continue;
        }

        final compressedPath = mediaInfo.path!;
        final compressedBytes = await File(compressedPath).length();
        final compressedMb = compressedBytes / (1024.0 * 1024.0);

        log(
          'Compressed to ${compressedMb.toStringAsFixed(2)} MB with $quality',
        );

        if (compressedMb <= maxSizeMb) {
          await originalFile.delete();
          return compressedPath;
        }
      } catch (e, st) {
        log('Video compression failed at $quality: $e\n$st');
      }
    }

    log(
      'Video compression could not reach ≤ ${maxSizeMb}MB → returning original',
    );
    return path;
  }

  static Future<String?> downloadImageToFile(String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(url, filePath);
      return filePath;
    } catch (e) {
      debugPrint("Error downloading image: $e");
      return null;
    }
  }

  static Future<void> clearOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = tempDir.listSync();
      for (final entity in entities) {
        if (entity is File &&
            (entity.path.contains('_compressed.') ||
                entity.path.contains('video_compress'))) {
          await entity.delete();
        }
      }
    } catch (e) {
      log('Error cleaning temp files: $e');
    }
  }
}

class _VideoProgressDialog extends StatefulWidget {
  const _VideoProgressDialog();

  @override
  State<_VideoProgressDialog> createState() => _VideoProgressDialogState();
}

class _VideoProgressDialogState extends State<_VideoProgressDialog> {
  double _progress = 0;
  dynamic _subscription;

  @override
  void initState() {
    super.initState();
    // ObservableBuilder in VideoCompress uses .subscribe()
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    // Unsubscribe to avoid memory leaks
    try {
      _subscription?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoadingIndicator(
      size: 60,
      isDeterminate: true,
      showPercentage: true,
      value: _progress / 100.0,
    );
  }
}
