import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/files/services/cloudinary_service.dart';

class CloudinaryTestWidget extends StatefulWidget {
  const CloudinaryTestWidget({super.key});

  @override
  State<CloudinaryTestWidget> createState() => _CloudinaryTestWidgetState();
}

class _CloudinaryTestWidgetState extends State<CloudinaryTestWidget> {
  String _status = 'Ready to test';
  bool _testing = false;

  Future<void> _testUploadPreset() async {
    setState(() {
      _testing = true;
      _status = 'Testing upload preset...';
    });

    try {
      final result = await CloudinaryService.instance.testUploadPreset();
      setState(() {
        _status = result ? '✅ Upload preset works!' : '❌ Upload preset failed';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Test error: $e';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cloudinary Test',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _testing ? null : _testUploadPreset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: _testing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Test Upload Preset',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}