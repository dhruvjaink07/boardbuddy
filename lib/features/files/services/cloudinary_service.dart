import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';

part 'cloudinary_service.g.dart';

@HiveType(typeId: 0)
class UploadedFileMetadata extends HiveObject {
  @HiveField(0)
  final String filename;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String publicId;

  @HiveField(3)
  final int size;

  @HiveField(4)
  final String resourceType;

  @HiveField(5)
  final DateTime uploadedAt;

  @HiveField(6)
  final String folder;

  @HiveField(7)
  final String fileType;

  UploadedFileMetadata({
    required this.filename,
    required this.url,
    required this.publicId,
    required this.size,
    required this.resourceType,
    required this.uploadedAt,
    required this.folder,
    required this.fileType,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'url': url,
    'publicId': publicId,
    'size': size,
    'resourceType': resourceType,
    'uploadedAt': uploadedAt.toIso8601String(),
    'folder': folder,
    'fileType': fileType,
  };

  factory UploadedFileMetadata.fromJson(Map<String, dynamic> json) {
    return UploadedFileMetadata(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
      size: json['size'] ?? 0,
      resourceType: json['resourceType'] ?? 'auto',
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
      folder: json['folder'] ?? 'boardbuddy',
      fileType: json['fileType'] ?? 'file',
    );
  }
}

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const String cloudName = 'dzkxylioj';
  static const String uploadPreset = 'boardbuddy'; // FIXED: Remove /attachments from preset name
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
  static const String cacheBoxName = 'cloudinary_uploads';

  late Box<UploadedFileMetadata> _cacheBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UploadedFileMetadataAdapter());
    }
    
    _cacheBox = await Hive.openBox<UploadedFileMetadata>(cacheBoxName);
    _isInitialized = true;
  }

  String _detectFileType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
      case 'bmp':
        return 'image';
      
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'mkv':
        return 'video';
      
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
      case 'm4a':
        return 'audio';
      
      case 'pdf':
        return 'pdf';
      
      case 'doc':
      case 'docx':
        return 'document';
      
      case 'xls':
      case 'xlsx':
        return 'spreadsheet';
      
      case 'ppt':
      case 'pptx':
        return 'presentation';
      
      case 'txt':
      case 'rtf':
        return 'text';
      
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return 'archive';
      
      case 'html':
      case 'htm':
      case 'css':
      case 'js':
      case 'json':
      case 'xml':
        return 'code';
      
      default:
        return 'file';
    }
  }

  Future<UploadedFileMetadata?> upload({
    File? file,
    Uint8List? bytes,
    required String filename,
    String folder = 'boardbuddy',
  }) async {
    await init();

    try {
      print('🚀 Starting Cloudinary upload...');
      print('   Cloud Name: $cloudName');
      print('   Upload Preset: $uploadPreset');
      print('   Filename: $filename');
      print('   Folder: $folder');

      final dio = Dio();

      final form = <String, dynamic>{
        'upload_preset': uploadPreset,
        'folder': folder,
        'resource_type': 'auto',
        'public_id': '${folder}/${DateTime.now().millisecondsSinceEpoch}_${filename.replaceAll(' ', '_')}',
      };

      if (kIsWeb) {
        if (bytes == null) {
          print('❌ No bytes provided for web upload');
          return null;
        }
        form['file'] = MultipartFile.fromBytes(bytes, filename: filename);
        print('📱 Web upload: ${bytes.length} bytes');
      } else {
        if (file == null) {
          print('❌ No file provided for mobile upload');
          return null;
        }
        form['file'] = await MultipartFile.fromFile(file.path, filename: filename);
        print('📱 Mobile upload: ${file.path}');
      }

      print('📤 Form data prepared: ${form.keys.join(', ')}');

      final formData = FormData.fromMap(form);
      
      // Add timeout and better error handling
      final res = await dio.post(
        uploadUrl, 
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          validateStatus: (status) {
            return status != null && status < 500; // Accept all status codes below 500
          },
        ),
      );

      print('📥 Response status: ${res.statusCode}');
      print('📥 Response data: ${res.data}');

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        
        final metadata = UploadedFileMetadata(
          filename: filename,
          url: data['secure_url'] ?? data['url'] ?? '',
          publicId: data['public_id'] ?? '',
          size: data['bytes'] ?? 0,
          resourceType: data['resource_type'] ?? 'auto',
          uploadedAt: DateTime.now(),
          folder: folder,
          fileType: _detectFileType(filename),
        );

        // Cache the metadata
        await _cacheUpload(metadata);
        
        print('✅ Upload successful!');
        print('   URL: ${metadata.url}');
        print('   Public ID: ${metadata.publicId}');
        
        return metadata;
      } else {
        print('❌ Upload failed with status: ${res.statusCode}');
        print('❌ Error response: ${res.data}');
        return null;
      }
    } catch (e) {
      print('❌ CloudinaryService upload error: $e');
      if (e is DioException) {
        print('❌ Dio error type: ${e.type}');
        print('❌ Dio error message: ${e.message}');
        print('❌ Dio response: ${e.response?.data}');
      }
      return null;
    }
  }

  Future<void> _cacheUpload(UploadedFileMetadata metadata) async {
    try {
      await _cacheBox.put(metadata.publicId, metadata);
      print('💾 Cached upload metadata: ${metadata.publicId}');
    } catch (e) {
      print('❌ Failed to cache upload metadata: $e');
    }
  }

  // Test method to verify upload preset
  Future<bool> testUploadPreset() async {
    try {
      print('🧪 Testing upload preset...');
      
      // Create a tiny test file
      final testData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
      
      final dio = Dio();
      final form = FormData.fromMap({
        'upload_preset': uploadPreset,
        'file': testData,
        'folder': 'test',
      });
      
      final response = await dio.post(uploadUrl, data: form);
      
      print('✅ Upload preset test successful: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Upload preset test failed: $e');
      return false;
    }
  }

  List<UploadedFileMetadata> getCachedUploads({String? folder}) {
    if (!_isInitialized) return [];
    
    final allUploads = _cacheBox.values.toList();
    
    if (folder != null) {
      return allUploads.where((upload) => upload.folder == folder).toList();
    }
    
    return allUploads;
  }

  UploadedFileMetadata? getCachedUpload(String publicId) {
    if (!_isInitialized) return null;
    return _cacheBox.get(publicId);
  }

  Future<bool> deleteCachedUpload(String publicId) async {
    if (!_isInitialized) return false;
    
    try {
      await _cacheBox.delete(publicId);
      return true;
    } catch (e) {
      print('Failed to delete cached upload: $e');
      return false;
    }
  }

  Future<void> clearCache() async {
    if (!_isInitialized) return;
    await _cacheBox.clear();
  }

  int get cachedUploadsCount => _isInitialized ? _cacheBox.length : 0;

  Future<void> dispose() async {
    if (_isInitialized) {
      await _cacheBox.close();
      _isInitialized = false;
    }
  }
}