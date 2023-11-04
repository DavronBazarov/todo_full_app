import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:todo_full_app/models/task.dart';

class HttpServices extends ChangeNotifier{
  Future<void> addTodo(Task task, String userId, String authToken) async {
    final url = Uri.parse(
      'https://online-shopp-provider-default-rtdb.firebaseio.com/tasks.json?auth=$authToken',
    );
    try {
      final response = await http.post(
        url,
        body: jsonEncode(
          {
            'creatorId': userId,
            'taskId': task.taskId.toIso8601String(),
            'taskName': task.taskName,
            'createdTime': task.createdTime,
            'createdDate': task.createdDate.toIso8601String(),
            'deadLineDate': task.deadLineDate,
            'deadLineTime': task.deadLineTime,
            'completedOn': task.completedOn.toIso8601String(),
            'isImportant': task.isImportant,
            'isFinished': task.isFinished,
          },
        ),
      );
    } catch (error) {
      rethrow;
    }
  }
}
