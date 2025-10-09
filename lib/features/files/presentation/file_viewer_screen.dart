import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FileViewerScreen extends StatefulWidget {
  final String name;
  final String url;
  final String type; // 'image','video','audio','pdf','document', etc.

  const FileViewerScreen({
    super.key,
    required this.name,
    required this.url,
    required this.type,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  WebViewController? _controller; // lazy init after first frame
  bool _isLoading = true;
  String? _webViewError; // fallback if platform view not registered

  bool get _isImage => const ['image', 'img', 'picture'].contains(widget.type);
  bool get _isVideo => const ['video'].contains(widget.type);
  bool get _isAudio => const ['audio'].contains(widget.type);
  bool get _isPdf => const ['pdf'].contains(widget.type);
  bool get _isDocLike => const ['document', 'spreadsheet', 'presentation', 'text', 'code'].contains(widget.type);

  @override
  void initState() {
    super.initState();
    if (!_isImage) {
      // Defer WebView creation until after first frame to avoid plugin init races
      WidgetsBinding.instance.addPostFrameCallback((_) => _initWebView());
    }
  }

  Future<void> _initWebView() async {
    try {
      final c = WebViewController()
        ..setBackgroundColor(Colors.black)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _webViewError = 'Failed to load content';
            _isLoading = false;
          }),
        ));
      setState(() => _controller = c);
      await _loadContent();
    } catch (e) {
      setState(() {
        _webViewError = 'WebView unavailable (${e.runtimeType})';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContent() async {
    if (_controller == null) return;

    if (_isPdf || _isDocLike) {
      final docsUrl = 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(widget.url)}';
      await _controller!.loadRequest(Uri.parse(docsUrl));
      return;
    }

    final html = _buildHtml(widget.url, widget.type);
    // Avoid baseUrl param for broader version compatibility
    await _controller!.loadHtmlString(html);
  }

  String _buildHtml(String url, String type) {
    final escapedUrl = htmlEscape.convert(url);
    final isVideo = _isVideo;
    final isAudio = _isAudio;

    final media = isVideo
        ? '<video controls playsinline style="max-width:100%;max-height:100%;background:black" src="$escapedUrl"></video>'
        : isAudio
            ? '<audio controls style="width:100%" src="$escapedUrl"></audio>'
            : '<iframe src="$escapedUrl" style="border:0;width:100%;height:100%"></iframe>';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
  <style>
    html,body { margin:0; padding:0; height:100%; background:#000; color:#fff; }
    .wrap { position:fixed; inset:0; display:flex; align-items:center; justify-content:center; }
  </style>
</head>
<body>
  <div class="wrap">
    $media
  </div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _webViewError != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.name, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isImage
          ? InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const CircularProgressIndicator(),
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white70),
                ),
              ),
            )
          : Stack(
              children: [
                if (!fallback && _controller != null) WebViewWidget(controller: _controller!),
                if (fallback)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.web_asset_off, color: Colors.white70, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            _webViewError!,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isLoading && !fallback)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}