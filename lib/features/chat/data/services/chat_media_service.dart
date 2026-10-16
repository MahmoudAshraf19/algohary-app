import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatMediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Compresses an image aggressively (WhatsApp style)
  Future<File?> compressImage(File file) async {
    if (kIsWeb) return file; // Skip advanced compression on web

    try {
      final fileSizeBefore = await file.length();
      debugPrint('📦 Original Image Size: ${(fileSizeBefore / (1024 * 1024)).toStringAsFixed(2)} MB');

      final targetPath = '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final fileSizeAfter = await compressedFile.length();
        debugPrint('🚀 Compressed Image Size: ${(fileSizeAfter / (1024 * 1024)).toStringAsFixed(2)} MB');
        return compressedFile;
      }
    } catch (e) {
      debugPrint('❌ [ImageCompress] Error: $e');
    }
    return file; // Fallback
  }

  /// Compresses a video aggressively
  Future<File?> compressVideo(File file) async {
    if (kIsWeb) return file; // Skip on web

    try {
      final fileSizeBefore = await file.length();
      debugPrint('📦 Original Video Size: ${(fileSizeBefore / (1024 * 1024)).toStringAsFixed(2)} MB');

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        final fileSizeAfter = await info.file!.length();
        debugPrint('🚀 Compressed Video Size: ${(fileSizeAfter / (1024 * 1024)).toStringAsFixed(2)} MB');
        return info.file;
      }
    } catch (e) {
      debugPrint('❌ [VideoCompress] Error: $e');
    }
    return file; // Fallback
  }

  /// Uploads media to Firebase Storage
  Future<String?> uploadMedia(File file, String folder, String type) async {
    try {
      File fileToUpload = file;

      // Compress if Mobile
      if (!kIsWeb) {
        if (type == 'IMAGE') {
          fileToUpload = await compressImage(file) ?? file;
        } else if (type == 'VIDEO') {
          fileToUpload = await compressVideo(file) ?? file;
        }
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('chats/$folder/$fileName');
      
      final uploadTask = await ref.putFile(fileToUpload);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ [UploadMedia] Error: $e');
      return null;
    }
  }

  /// Uploads media to Firebase Storage (specifically for Web)
  Future<String?> uploadWebMedia(XFile xfile, String folder, String type) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
      final ref = _storage.ref().child('chats/$folder/$fileName');
      
      var bytes = await xfile.readAsBytes();
      debugPrint('📦 Original Web Media Size: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB');
      
      if (type == 'IMAGE') {
        try {
          final compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            quality: 70,
            format: CompressFormat.jpeg,
          );
          bytes = compressedBytes;
          debugPrint('🚀 Compressed Web Media Size: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB');
        } catch (e) {
          debugPrint('⚠️ Web Image Compression Failed: $e');
        }
      }

      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ [UploadWebMedia] Error: $e');
      return null;
    }
  }

  /// Uploads media to Firebase Storage from a web blob URL (e.g. recorded voice)
  Future<String?> uploadWebBlob(String blobUrl, String folder, String extension) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = _storage.ref().child('chats/$folder/$fileName');
      
      final response = await Dio().get(
        blobUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data);
      
      debugPrint('📦 Web Blob Media Size: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB');
      
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ [UploadWebBlob] Error: $e');
      return null;
    }
  }

  /// Pick multiple media (fallback / web)
  Future<List<XFile>> pickMultiMedia() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(limit: 10);
    return pickedFiles;
  }

  /// Pick single media (fallback / web)
  Future<XFile?> pickMedia(bool isVideo) async {
    final XFile? pickedFile = isVideo 
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);
    
    return pickedFile;
  }
}
