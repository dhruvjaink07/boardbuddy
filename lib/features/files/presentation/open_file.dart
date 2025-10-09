import 'package:flutter/material.dart';
import 'package:boardbuddy/features/files/presentation/file_viewer_screen.dart';

void openAttachmentViewer(
  BuildContext context, {
  required String name,
  required String url,
  required String type,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FileViewerScreen(name: name, url: url, type: type),
    ),
  );
}