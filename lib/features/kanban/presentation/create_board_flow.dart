import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:boardbuddy/routes/app_routes.dart';
import 'package:boardbuddy/features/kanban/data/ai_board_service.dart';
import 'package:boardbuddy/features/board/presentation/board_view_screen.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateBoardPage extends StatefulWidget {
  const CreateBoardPage({super.key});

  @override
  State<CreateBoardPage> createState() => _CreateBoardPageState();
}

class _CreateBoardPageState extends State<CreateBoardPage> {
  final TextEditingController _boardNameController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  String selectedTheme = "Purple Galaxy";
  Gradient selectedGradient = LinearGradient(
    colors: [AppColors.purple, AppColors.purpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String selectedStartMethod = 'ai';
  bool _isGenerating = false;

  void _selectTheme(String theme, Gradient gradient) {
    setState(() {
      selectedTheme = theme;
      selectedGradient = gradient;
    });
  }

  Future<void> _createBoard() async {
    String boardName = _boardNameController.text.isEmpty 
        ? "Untitled Board" 
        : _boardNameController.text;

    if (selectedStartMethod == 'ai') {
      await _createAIBoard(boardName);
    } else {
      _createManualBoard(boardName);
    }
  }

  Future<void> _createAIBoard(String boardName) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        'Missing Prompt',
        'Please describe your project or goal to generate the board.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Sign in required', 'Please sign in to generate a board.');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final aiResponse = await AIBoardService.generateBoardFromPrompt(
        boardName: boardName,
        prompt: prompt,
        theme: selectedTheme.toLowerCase().replaceAll(' ', '_'),
        userId: userId,
      );

      // Parse the AI response
      final rawBoard = AIBoardService.parseBoard(aiResponse['board']);
      final columns = AIBoardService.parseColumns(aiResponse['columns']);
      final List<task_model.TaskCard> tasks =
          AIBoardService.parseTasks(aiResponse['tasks']).cast<task_model.TaskCard>();

      final board = rawBoard.copyWith(
        ownerId: userId,
        memberIds: [userId],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // Group tasks by column
      final tasksByColumn = <String, List<task_model.TaskCard>>{};
      for (final column in columns) {
        tasksByColumn[column.columnId] = tasks
            .where((task) => task.columnId == column.columnId)
            .toList();
      }

      // Persist to Firestore
      await BoardFirestoreService.instance.saveGeneratedBoard(
        board: board,
        columns: columns,
        tasksByColumn: tasksByColumn,
      );

      // Navigate to board view
      Get.off(() => BoardViewScreen(
        board: board,
        columnsMeta: columns,
        tasksByColumn: tasksByColumn,
      ));

      Get.snackbar(
        'Board Created Successfully!',
        'Your AI-generated board is ready to use.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.1),
        colorText: AppColors.success,
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      Get.snackbar(
        'Generation Failed',
        'Failed to generate board: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _createManualBoard(String boardName) {
    // Navigate to manual setup
    Get.toNamed(AppRoutes.manualBoardSetupScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          // FIX: pop instead of pushing another BoardScreen
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          "Create New Board",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Board Name Input
            const Text(
              "Board Name",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _boardNameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: "e.g., Final Year Project, Marketing Plan",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Choose How to Start
            const Text(
              "Choose How to Start",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Method Selection Cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedStartMethod = 'ai'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surface,
                        border: Border.all(
                          color: selectedStartMethod == 'ai'
                              ? AppColors.primary.withOpacity(0.95)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: selectedStartMethod == 'ai'
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: selectedStartMethod == 'ai' ? AppColors.primary : AppColors.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "AI Generator",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Describe your goal, we'll build your board",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedStartMethod = 'manual');
                      _createManualBoard(_boardNameController.text.toString());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surface,
                        border: Border.all(
                          color: selectedStartMethod == 'manual'
                              ? AppColors.primary.withOpacity(0.95)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: selectedStartMethod == 'manual'
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.edit,
                              color: selectedStartMethod == 'manual' ? AppColors.primary : AppColors.textSecondary,
                              size: 28),
                          const SizedBox(height: 12),
                          Text(
                            "Manual Setup",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Create your own from scratch",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Prompt Input
            TextField(
              controller: _promptController,
              maxLines: 3,
              enabled: selectedStartMethod == 'ai',
              style: TextStyle(
                color: selectedStartMethod == 'ai' ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: selectedStartMethod == 'ai' 
                    ? "Describe your project or goal in detail. e.g., 'Build a mobile app for food delivery with features like user registration, restaurant browsing, order management, and payment integration'"
                    : "Prompt disabled for manual setup",
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Board Theme Section
            const Text(
              "Pick a Board Theme",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Theme cards
            Row(
              children: [
                Expanded(
                  child: _themeCard(
                    "Purple Galaxy",
                    "Research & Study",
                    LinearGradient(
                      colors: [AppColors.purple, AppColors.purpleLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    Icons.star,
                    selectedTheme == "Purple Galaxy",
                    () => _selectTheme(
                      "Purple Galaxy",
                      LinearGradient(
                        colors: [AppColors.purple, AppColors.purpleLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _themeCard(
                    "Forest Green",
                    "Travel & Nature",
                    LinearGradient(
                      colors: [AppColors.success, AppColors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    Icons.eco,
                    selectedTheme == "Forest Green",
                    () => _selectTheme(
                      "Forest Green",
                      LinearGradient(
                        colors: [AppColors.success, AppColors.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _themeCard(
                    "Neon Red",
                    "Events & Goals",
                    LinearGradient(
                      colors: [AppColors.pink, AppColors.error],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    Icons.flash_on,
                    selectedTheme == "Neon Red",
                    () => _selectTheme(
                      "Neon Red",
                      LinearGradient(
                        colors: [AppColors.pink, AppColors.error],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _themeCard(
                    "Sky Blue",
                    "Work & Tasks",
                    LinearGradient(
                      colors: [AppColors.skyBlue, AppColors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    Icons.work,
                    selectedTheme == "Sky Blue",
                    () => _selectTheme(
                      "Sky Blue",
                      LinearGradient(
                        colors: [AppColors.skyBlue, AppColors.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preview Section
            const Text(
              "Preview",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),

            _PreviewBoardWidget(
              gradient: selectedGradient,
              title: _boardNameController.text.isEmpty ? "Untitled Board" : _boardNameController.text,
            ),
            const SizedBox(height: 30),

            // Create Board Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _isGenerating ? null : _createBoard,
                child: _isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Generating Board...",
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          ),
                        ],
                      )
                    : Text(
                        selectedStartMethod == 'ai' ? "Generate with AI" : "Create Board",
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fixed Theme Card method
  Widget _themeCard(
    String title,
    String subtitle,
    Gradient gradient,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: AppColors.selectionGlow.withOpacity(0.9), width: 2) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.selectionGlow.withOpacity(0.16),
                    blurRadius: 18,
                    spreadRadius: 4,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 28),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Move all preview-related classes outside of the main state class
class _PreviewBoardWidget extends StatelessWidget {
  final Gradient gradient;
  final String title;

  const _PreviewBoardWidget({
    super.key,
    required this.gradient,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.black.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(child: _AlignedPreviewColumn(label: "To Do")),
                        SizedBox(width: 12),
                        Expanded(child: _AlignedPreviewColumn(label: "In Progress")),
                        SizedBox(width: 12),
                        Expanded(child: _AlignedPreviewColumn(label: "Done")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlignedPreviewColumn extends StatelessWidget {
  final String label;
  const _AlignedPreviewColumn({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Column(
            children: [
              _MiniPreviewCard(),
              const SizedBox(height: 8),
              _MiniPreviewCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniPreviewCard extends StatelessWidget {
  const _MiniPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
