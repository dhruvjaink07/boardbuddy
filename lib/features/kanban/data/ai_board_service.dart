import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/models/board_column.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';
import 'package:boardbuddy/config.dart';

class AIBoardService {
  static const String APIKEY = Config.APIKEY;
  
  static Future<Map<String, dynamic>> generateBoardFromPrompt({
    required String boardName,
    required String prompt, 
    required String theme,
    required String userId,
  }) async {
    print('🚀 Starting AI Board Generation...');
    print('📝 Board Name: $boardName');
    print('🎨 Theme: $theme');
    print('💭 User Prompt: $prompt');
    print('👤 User ID: $userId');
    print('═══════════════════════════════════════');
    
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: APIKEY);

    final now = DateTime.now();
    final boardId = 'board_${now.millisecondsSinceEpoch}';

    String systemPrompt = """
    You are a Kanban board generator assistant. 
    Generate a structured Kanban board based on the user's requirements.
    The response should be in **JSON format only**, without any extra text or markdown formatting.

    Here's the required format:

    {
      "board": {
        "boardId": "$boardId",
        "name": "Board Name",
        "description": "Brief description of the board's purpose",
        "theme": "Theme name",
        "ownerId": "$userId",
        "memberIds": ["$userId"],
        "maxEditors": 5,
        "createdAt": "${now.toIso8601String()}",
        "lastUpdated": "${now.toIso8601String()}"
      },
      "columns": [
        {
          "columnId": "unique_column_id",
          "title": "Column Title",
          "order": 0,
          "createdAt": "${now.toIso8601String()}"
        }
      ],
      "tasks": [
        {
          "id": "unique_task_id",
          "title": "Task Title",
          "description": "Detailed task description",
          "status": "todo",
          "priority": "medium",
          "assigneeId": "$userId",
          "labels": ["label1", "label2"],
          "dueDate": "2024-12-31T23:59:59.000Z",
          "createdAt": "${now.toIso8601String()}",
          "updatedAt": "${now.toIso8601String()}",
          "columnId": "column_id_where_task_belongs",
          "category": "General",
          "assignees": ["user1", "user2"],
          "progress": 0.0,
          "subtasks": [
            {
              "id": "subtask_id",
              "title": "Subtask title",
              "isCompleted": false,
              "createdAt": "${now.toIso8601String()}"
            }
          ],
          "attachments": [],
          "comments": []
        }
      ]
    }

    Guidelines:
    1. Create 3-5 columns that make sense for the project type
    2. Generate 8-15 tasks distributed across columns logically
    3. Each task should have 0-3 subtasks
    4. Use appropriate priorities: "low", "medium", "high", "urgent"
    5. Use relevant labels that categorize tasks
    6. Set realistic due dates (within next 1-3 months)
    7. Tasks should be actionable and specific
    8. Column titles should be clear and workflow-oriented
    9. Include category, assignees, and progress fields for each task

    Now generate a Kanban board for:
    - Board Name: "$boardName"
    - Theme: "$theme" 
    - User Requirements: "$prompt"
    
    Make sure the board is comprehensive and ready to use for the described project or goal.
    """;

    print('🤖 Sending request to Gemini AI...');
    final content = [Content.text(systemPrompt)];
    final response = await model.generateContent(content);
    
    print('✅ Response received from Gemini AI');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 RAW AI RESPONSE:');
    print(response.text ?? 'No response text');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (response.text == null) {
      print('❌ Error: No response text from AI');
      throw Exception("Could not generate board content.");
    }

    try {
      print('🔧 Processing AI response...');
      // Clean the response to ensure it's valid JSON
      String jsonText = response.text!.trim();
      
      print('📏 Original response length: ${jsonText.length}');
      
      // Remove any markdown code block formatting if present
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
        print('🧹 Removed ```json prefix');
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
        print('🧹 Removed ``` prefix');
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
        print('🧹 Removed ``` suffix');
      }
      
      print('📏 Cleaned response length: ${jsonText.length}');
      print('🔧 Attempting JSON parsing...');
      
      final Map<String, dynamic> jsonResponse = json.decode(jsonText);
      
      print('✅ JSON parsing successful!');
      print('📊 Generated board structure:');
      print('   - Board ID: ${jsonResponse['board']?['boardId']}');
      print('   - Board Name: ${jsonResponse['board']?['name']}');
      print('   - Columns: ${jsonResponse['columns']?.length ?? 0}');
      print('   - Tasks: ${jsonResponse['tasks']?.length ?? 0}');
      
      if (jsonResponse['columns'] != null) {
        print('📋 Column titles:');
        for (var column in jsonResponse['columns']) {
          print('   • ${column['title']}');
        }
      }
      
      if (jsonResponse['tasks'] != null) {
        print('📝 Task distribution:');
        Map<String, int> taskCounts = {};
        for (var task in jsonResponse['tasks']) {
          String columnId = task['columnId'] ?? 'unknown';
          taskCounts[columnId] = (taskCounts[columnId] ?? 0) + 1;
        }
        taskCounts.forEach((columnId, count) {
          print('   • $columnId: $count tasks');
        });
      }
      
      print('🎉 AI Board Generation completed successfully!');
      return jsonResponse;
      
    } catch (e) {
      print('❌ JSON parsing error: $e');
      print('📄 Raw response for debugging:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(response.text);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception("Failed to parse AI response: $e");
    }
  }

  static Board parseBoard(Map<String, dynamic> boardData) {
    print('🏗️ Parsing board data...');
    return Board(
      boardId: boardData['boardId'] ?? '',
      name: boardData['name'] ?? 'Untitled Board',
      description: boardData['description'] ?? '',
      theme: boardData['theme'] ?? 'default',
      ownerId: boardData['ownerId'] ?? '',
      memberIds: List<String>.from(boardData['memberIds'] ?? []),
      maxEditors: boardData['maxEditors'] ?? 5,
      createdAt: DateTime.parse(boardData['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(boardData['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  static List<BoardColumn> parseColumns(List<dynamic> columnsData) {
    print('📋 Parsing ${columnsData.length} columns...');
    return columnsData.map((columnData) {
      return BoardColumn(
        columnId: columnData['columnId'] ?? '',
        title: columnData['title'] ?? 'Untitled Column',
        order: columnData['order'] ?? 0,
        createdAt: DateTime.parse(columnData['createdAt'] ?? DateTime.now().toIso8601String()),
      );
    }).toList();
  }

  static List<TaskCard> parseTasks(List<dynamic> tasksData) {
    print('📝 Parsing ${tasksData.length} tasks...');
    return tasksData.map((taskData) {
      final map = Map<String, dynamic>.from(taskData as Map);
      // Normalize keys to our model
      map['tags'] = map['tags'] ?? map['labels'] ?? const <String>[];
      map['updatedAt'] = map['updatedAt'] ?? map['lastUpdated'];
      return TaskCard.fromMap(map);
    }).toList();
  }
}