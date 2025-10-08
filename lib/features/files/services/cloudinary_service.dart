import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const String cloudName = 'dx28ndbq1';
  static const String uploadPreset = 'skillBridge';

  // Use resource_type=auto so images, pdf, etc. work
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  Future<String?> upload({
    File? file,
    Uint8List? bytes,
    required String filename,
    String folder = 'boardbuddy',
  }) async {
    try {
      final dio = Dio();

      final form = <String, dynamic>{
        'upload_preset': uploadPreset,
        'folder': folder,
      };

      if (kIsWeb) {
        if (bytes == null) return null;
        form['file'] = MultipartFile.fromBytes(bytes, filename: filename);
      } else {
        if (file == null) return null;
        form['file'] = await MultipartFile.fromFile(file.path, filename: filename);
      }

      final formData = FormData.fromMap(form);
      final res = await dio.post(uploadUrl, data: formData);

      if (res.statusCode == 200 && res.data is Map) {
        return (res.data['secure_url'] as String?) ?? res.data['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}