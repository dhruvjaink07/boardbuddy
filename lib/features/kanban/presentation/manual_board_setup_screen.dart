import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:get/route_manager.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/models/board_column.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:boardbuddy/features/board/presentation/board_view_screen.dart';
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManualBoardSetupScreen extends StatefulWidget {
  const ManualBoardSetupScreen({super.key});

  @override
  State<ManualBoardSetupScreen> createState() => _ManualBoardSetupScreenState();
}

class _ManualBoardSetupScreenState extends State<ManualBoardSetupScreen> {
  final TextEditingController _boardNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _stageControllers = [];
  String _selectedTheme = 'forest';

  @override
  void initState() {
    super.initState();
    // rebuild when board name changes so preview updates live
    _boardNameController.addListener(_onBoardNameChanged);

    // default stages
    _addStageWithText('To Do');
    _addStageWithText('In Progress');
    _addStageWithText('Done');
  }

  void _onBoardNameChanged() {
    setState(() {}); // trigger rebuild to refresh preview title
  }

  void _addStageWithText([String text = '']) {
    final c = TextEditingController(text: text);
    setState(() {
      _stageControllers.add(c);
    });
  }

  void _removeStage(int index) {
    if (index < 0 || index >= _stageControllers.length) return;
    setState(() {
      _stageControllers[index].dispose();
      _stageControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    // remove listener before disposing
    _boardNameController.removeListener(_onBoardNameChanged);
    _boardNameController.dispose();
    _descriptionController.dispose();
    for (final c in _stageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCreateBoardPressed() {
    final name = _boardNameController.text.trim();
    final description = _descriptionController.text.trim();
    final theme = _selectedTheme ?? 'forest';

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Sign in required', 'Please sign in to create boards.');
      return;
    }

    // build column models
    final columns = <BoardColumn>[];
    for (var i = 0; i < _stageControllers.length; i++) {
      final title = _stageControllers[i].text.trim();
      if (title.isEmpty) continue;
      columns.add(BoardColumn(columnId: 'col_${i + 1}', title: title, order: i, createdAt: DateTime.now()));
    }
    if (columns.isEmpty) {
      columns.addAll([
        BoardColumn(columnId: 'todo', title: 'To Do', order: 0, createdAt: DateTime.now()),
        BoardColumn(columnId: 'inprogress', title: 'In Progress', order: 1, createdAt: DateTime.now()),
        BoardColumn(columnId: 'done', title: 'Done', order: 2, createdAt: DateTime.now()),
      ]);
    }

    // create Board model
    final board = Board(
      boardId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isEmpty ? 'Untitled Board' : name,
      description: description,
      theme: theme,
      ownerId: uid,
      memberIds: [uid],
      maxEditors: 5,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    // empty tasks
    final tasksByColumn = <String, List<task_model.TaskCard>>{
      for (final c in columns) c.columnId: <task_model.TaskCard>[],
    };

    // Persist to Firestore
    BoardFirestoreService.instance.saveGeneratedBoard(
      board: board,
      columns: columns,
      tasksByColumn: tasksByColumn,
    ).then((_) {
      // Show success message and navigate
      Get.snackbar(
        'Board Created!',
        'Your board has been created successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.1),
        colorText: AppColors.success,
      );

      // Navigate to board view
      Get.off(() => BoardViewScreen(
        board: board, 
        columnsMeta: columns, 
        tasksByColumn: tasksByColumn,
      ));
    }).catchError((error) {
      Get.snackbar(
        'Error',
        'Failed to create board: $error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    });
  }

  Widget _buildStageRow(int index, double height) {
    final controller = _stageControllers[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // index badge
          Container(
            width: 34,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // text field
          Expanded(
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Stage name',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // delete
          InkWell(
            onTap: () {
              _removeStage(index);
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.delete_outline, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // Replace the old _themeItem helper with a constrained tile builder
  Widget _themeTile({
    required String id,
    String? imageUrl,
    Gradient? gradient,
    required String label,
  }) {
    final bool selected = _selectedTheme == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 84, // fixed tile width to avoid layout surprises
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Constrain the preview image box so the whole Column fits within the parent
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 48, // short height so label + spacing fits
                decoration: imageUrl != null
                    ? BoxDecoration(   
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      )
                    : BoxDecoration(
                        gradient: gradient ?? LinearGradient(colors: [AppColors.surface, AppColors.card]),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 14, // constrain label height to prevent overflow
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
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
          onPressed: () => Get.back(), // Use Get.back() instead of Get.toNamed
        ),
        title: const Text('Manual Board Setup', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        // adapt vertical spacing and controls size
        final isWide = constraints.maxWidth > 600;
        final stageRowHeight = isWide ? 56.0 : 48.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // board name
              const Text('Board Name', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _boardNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'e.g., Portfolio Website, Internship Tracker',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // stages header
              const Text('Define Stages (Kanban Columns)', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 10),

              // stages list
              Column(
                children: List.generate(_stageControllers.length, (i) => _buildStageRow(i, stageRowHeight)),
              ),

              // add stage button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addStageWithText(),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text('+ Add Stage', style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // description
              const Text('Add Descriptions (Optional)', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textSecondary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'This board will be used for...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // choose theme label
              const Text('Choose Board Theme', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 10),

              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _themeTile(
                      id: 'forest',
                      imageUrl:
                          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
                      label: 'Forest',
                    ),
                    _themeTile(
                      id: 'space',
                      gradient: const LinearGradient(colors: [Colors.black87, Colors.blueGrey]),
                      label: 'Space',
                    ),
                    _themeTile(
                      id: 'neon',
                      gradient: const LinearGradient(colors: [AppColors.pink, AppColors.purpleLight]),
                      label: 'Neon',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // preview
              const Text('Preview', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _ManualPreview(
                name: _boardNameController.text.isEmpty ? 'Portfolio Website' : _boardNameController.text,
                stages: _stageControllers.map((c) => c.text.isEmpty ? 'Stage' : c.text).toList(),
                theme: _selectedTheme,
              ),

              const SizedBox(height: 20),

              // create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // FIX: actually create the board
                  onPressed: _onCreateBoardPressed,
                  child: const Text('Create Board', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

class _ManualPreview extends StatelessWidget {
  final String name;
  final List<String> stages;
  final String theme;
  const _ManualPreview({super.key, required this.name, required this.stages, required this.theme});

  Gradient _themeGradient() {
    switch (theme) {
      case 'space':
        return const LinearGradient(colors: [Colors.black87, Colors.blueGrey]);
      case 'neon':
        return const LinearGradient(colors: [AppColors.pink, AppColors.purpleLight]);
      case 'forest':
      default:
        return const LinearGradient(colors: [Color(0xFF2E8B57), Color(0xFF4CAF50)]);
    }
  }

  Widget _columnCard(BuildContext c, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // header row
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('0', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // add placeholder area
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 160, maxHeight: 96),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white54, size: 22),
                      SizedBox(height: 6),
                      Text('Add', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftPreview(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: _themeGradient(),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: stages.take(3).map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleStages = stages.isEmpty ? ['To Do', 'In Progress', 'Done'] : stages;
    final items = List<String>.from(visibleStages);
    while (items.length < 3) items.add('Stage');
    final cols = items.take(3).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 520;
      // animated size so preview can expand/collapse smoothly
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            // responsive layout: stacked (mobile) or split (tablet/desktop)
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cols.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) {
                            return SizedBox(
                              width: 220,
                              child: _columnCard(ctx, cols[i]),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // left preview box
                      Expanded(flex: 2, child: _leftPreview(context)),
                      const SizedBox(width: 12),
                      // columns
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: List.generate(cols.length, (i) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                                child: _columnCard(context, cols[i]),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}