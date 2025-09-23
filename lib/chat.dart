import 'package:flutter/material.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat UI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1B1B1B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Board Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF4A4A4A), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              children: [
                _buildMessageBubble(
                  'I\'ve updated the project timeline in the shared document.',
                  false,
                  '10:30 AM',
                  fileAttachment: FileAttachment(
                    fileName: 'Project_Timeline_Q4.pdf',
                    fileIcon: Icons.insert_drive_file,
                  ),
                ),
                _buildMessageBubble(
                  'Thanks! I\'ll review it right away.',
                  true,
                  '10:32 AM',
                ),
                _buildMessageBubble(
                  'Here\'s the latest design mockup for the dashboard.',
                  false,
                  '10:35 AM',
                  fileAttachment: FileAttachment(
                    fileName: 'Dashboard_Design.fig',
                    fileIcon: Icons.insert_drive_file,
                  ),
                ),
                _buildMessageBubble(
                  'Looking good! The color scheme matches our brand guidelines perfectly.',
                  true,
                  '10:38 AM',
                ),
                _buildMessageBubble(
                  'Great! Let me know if you need any adjustments.',
                  false,
                  '10:40 AM',
                ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String message,
    bool isSender,
    String time, {
    FileAttachment? fileAttachment,
  }) {
    final Color messageColor = isSender
        ? const Color.fromARGB(255, 88, 47, 33)
        : const Color(0xFF333333);
    final Color textColor = isSender ? Colors.white : Colors.white;
    final Alignment alignment = isSender
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final BorderRadius borderRadius = isSender
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isSender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: messageColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: textColor, fontSize: 16)),
                if (fileAttachment != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A4A4A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fileAttachment.fileIcon,
                          color: const Color(0xFF8D8D8D),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fileAttachment.fileName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.link,
                          color: Color(0xFF8D8D8D),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isSender ? 0 : 8,
              right: isSender ? 8 : 0,
              bottom: 10,
            ),
            child: Text(
              time,
              style: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1B1B1B),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Color(0xFF8D8D8D)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF333333),
            ),
            child: IconButton(
              icon: const Icon(Icons.mic, color: Colors.white),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFC76934),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class FileAttachment {
  final String fileName;
  final IconData fileIcon;

  FileAttachment({required this.fileName, required this.fileIcon});
}
