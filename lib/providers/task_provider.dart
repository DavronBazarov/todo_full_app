import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  ///bu funksiya internet bor yo'qligini tekshiradi
  bool hasInternetValue = false;

  Future<bool> hasInternet() async {
    bool hasInternetValue = await InternetConnectionChecker().hasConnection;
    return hasInternetValue;
  }

  static const boxName = 'task box';

  String? _authToken;
  String? _userId;

  void setParams(String? authToken, String? userId) {
    _authToken = authToken;
    _userId = userId;
  }

  List<Task> _taskList = [];

  String stringOfDedTime = '';
  DateTime objectOfDedTime = DateTime.now();

  String stringOfSelectedDate = '';
  DateTime objectOfSelectedDate = DateTime.now();
  List<Task> _sortedTasksByDate = [];
  @override
  bool loading = true;

  Future<void> getAllTask() async {
    loading = true;
    if (await hasInternet()) {
      await getDateFromFirebase();
      await autoUpdateData();
      hasInternetValue = true;
    } else {
      hasInternetValue = false;
    }
    var box = await Hive.openBox<Task>(boxName);
    _taskList =
        box.values.where((element) => element.creatorId == _userId).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> getDateFromFirebase() async {
    final filterString = 'orderBy="creatorId"&equalTo="$_userId"';
    final url = Uri.parse(
      'https://online-shopp-provider-default-rtdb.firebaseio.com/tasks.json?&auth=$_authToken&$filterString',
    );
    try {
      final response = await http.get(url);

      log("get data======${response.body}");
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<Task> loadedTasks = [];
      var box = await Hive.openBox<Task>(boxName);
      data.forEach((taskIdOnFirebase, taskData) {
        loadedTasks.add(
          Task(
            creatorId: _userId,
            taskIdOnFirebase: taskIdOnFirebase,
            createdTime: taskData["createdTime"],
            deadLineDate: taskData['deadLineDate'],
            deadLineTime: taskData['deadLineTime'],
            taskName: taskData['taskName'],
            createdDate: DateTime.parse(taskData['createdDate']),
            isImportant: taskData['isImportant'],
            taskId: DateTime.parse(taskData['taskId']),
            isFinished: taskData['isFinished'],
            completedOn: DateTime.parse(taskData['completedOn']),
          ),
        );
      });
      List<Task> listDb = box.values.toList();
      // Create a set of names from list2 for efficient lookup
      Set<String> taskIdSet = listDb.isEmpty
          ? Set()
          : listDb
              .map((task) => task.taskId.toString().substring(0, 18))
              .toSet();

      // Find the missing Tasks in list1
      List<Task> missingTasks = loadedTasks.where((person) {
        if (taskIdSet == Set()) {
          return true;
        } else {
          return !taskIdSet.contains(person.taskId.toString().substring(0, 18));
        }
      }).toList();
      if (missingTasks.isNotEmpty) {
        missingTasks.forEach((task) async {
          await box.add(
            Task(
              creatorId: _userId,
              taskIdOnFirebase: task.taskIdOnFirebase,
              createdTime: task.createdTime,
              deadLineDate: task.deadLineDate,
              deadLineTime: task.deadLineTime,
              taskName: task.taskName,
              createdDate: task.createdDate,
              isImportant: task.isImportant,
              taskId: task.taskId,
              completedOn: task.completedOn,
            ),
          );
        });
      }
      hasInternetValue = true;
      missingTasks = [];
    } catch (e) {
      rethrow;
    }
  }

  List<Task> get getOtherTaskList {
    return [
      ..._sortedTasksByDate
          .where(
              (task) => task.isImportant == false && task.creatorId == _userId)
          .toList()
    ];
  }

  List<Task> get getPriortyList {
    List<Task> newPriorityList = _sortedTasksByDate
        .where((item) => item.isImportant == true && item.creatorId == _userId)
        .toList();
    return [...newPriorityList];
  }

  List<Task> get getCompletedTasksList {
    List<Task> completedTasks = _taskList
        .where((task) => task.isFinished == true && task.creatorId == _userId)
        .toList();
    return [...completedTasks];
  }

  void sortTaskByDate(DateTime date) async {
    objectOfSelectedDate = date;
    stringOfSelectedDate = DateFormat('dd-MM-yyyy').format(date);
    var box = await Hive.openBox<Task>(boxName);
    _sortedTasksByDate = box.values
        .where((task) =>
            task.deadLineDate == stringOfSelectedDate &&
            task.creatorId == _userId)
        .toList();
    _taskList = box.values.toList();

    notifyListeners();
  }

  int currentTotalTaskCount(List<Task> tskList) {
    return tskList.where((element) => element.creatorId == _userId).length;
  }

  int currentFinishedTaskCount(List<Task> tskList) {
    List<Task> newList = tskList
        .where((task) => task.isFinished == true && task.creatorId == _userId)
        .toList();
    return newList.length;
  }

  int get getTotalTaskCount {
    return _taskList.where((element) => element.creatorId == _userId).length;
  }

  int get getTotalDoneTaskCount {
    return getCompletedTasksList
        .where((element) => element.creatorId == _userId)
        .length;
  }

  Future<void> autoUpdateData() async {
    var box = await Hive.openBox<Task>(boxName);
    List<Task> checkingList = box.values.toList();
    for (var element in checkingList) {
      if (element.statusTaskForUpdate == "noClouded") {
        int editItemIndex = _taskList.indexOf(element);
        element.statusTaskForUpdate = "clouded";
        final String uploaded = await addNewTaskForFirebase(element);
        element.taskIdOnFirebase = uploaded;
        if (uploaded.isNotEmpty && element.creatorId == _userId) {
          await box.putAt(editItemIndex, element);
          _taskList = box.values
              .where((element) => element.creatorId == _userId)
              .toList();
        }
      }
      if (element.statusTaskForUpdate == "noEdited") {
        log("noEdited-----${element.taskName}");
        int editItemIndex = _taskList.indexOf(element);
        element.statusTaskForUpdate = "edited";
        final bool editedTask = await editTaskForFirebase(element);
        if (editedTask && element.creatorId == _userId) {
          await box.putAt(editItemIndex, element);
          _taskList = box.values
              .where((element) => element.creatorId == _userId)
              .toList();
        }
      }
      if (element.statusTaskForUpdate == "noToggle") {
        log("noToggle-----${element.taskName}");
        int editItemIndex = _taskList.indexOf(element);
        element.statusTaskForUpdate = "toggled";
        if (element.isFinished) {
          element.isFinished = false;
        } else {
          element.isFinished = true;
        }
        final bool editedTask = await editTaskForFirebase(element);
        if (editedTask && element.creatorId == _userId) {
          await box.putAt(editItemIndex, element);
          _taskList = box.values
              .where((element) => element.creatorId == _userId)
              .toList();
        }
      }
      notifyListeners();
    }
    loading = false;
    notifyListeners();
  }

  Future<String> addNewTaskForFirebase(Task task) async {
    if (await hasInternet()) {
      hasInternetValue = true;
      final url = Uri.parse(
        'https://online-shopp-provider-default-rtdb.firebaseio.com/tasks.json?auth=$_authToken',
      );
      try {
        final response = await http.post(
          url,
          body: jsonEncode(
            {
              'creatorId': _userId,
              'taskId': task.taskId.toIso8601String(),
              'taskName': task.taskName,
              'createdTime': task.createdTime,
              'createdDate': task.createdDate.toIso8601String(),
              'deadLineDate': task.deadLineDate,
              "statusTaskForUpdate": task.statusTaskForUpdate,
              'deadLineTime': task.deadLineTime,
              'completedOn': task.completedOn.toIso8601String(),
              'isImportant': task.isImportant,
              'isFinished': task.isFinished,
            },
          ),
        );
        print("responseBody =====---- ${response.body} ${response.statusCode}");
        final String taskIdOnFirebase =
            (jsonDecode(response.body) as Map<String, dynamic>)['name'];
        if (response.statusCode == 200) {
          hasInternetValue = true;
          return taskIdOnFirebase;
        } else {
          hasInternetValue = true;
          return "";
        }
      } catch (error) {
        rethrow;
      }
    } else {
      hasInternetValue = false;
      return "local";
    }
  }

  void addNewTaskDb(
      {required String crtTime,
      required String dedTime,
      required DateTime crtDate,
      required String dedDate,
      required String tskName,
      required bool isImportant}) async {
    print("------UserId=$_userId");

    ///ckeacking internet

    final String taskIdOnFirebase = await addNewTaskForFirebase(
      Task(
        statusTaskForUpdate: hasInternetValue ? "clouded" : "noClouded",
        creatorId: _userId,
        createdTime: crtTime,
        deadLineDate: dedDate,
        deadLineTime: dedTime,
        taskName: tskName,
        createdDate: crtDate,
        isImportant: isImportant,
        taskId: DateTime.now(),
        completedOn: DateTime.now(),
      ),
    );
    if (taskIdOnFirebase.isNotEmpty) {
      var box = await Hive.openBox<Task>(boxName);
      await box.add(
        Task(
          statusTaskForUpdate: hasInternetValue ? "clouded" : "noClouded",
          creatorId: _userId,
          taskIdOnFirebase: taskIdOnFirebase,
          createdTime: crtTime,
          deadLineDate: dedDate,
          deadLineTime: dedTime,
          taskName: tskName,
          createdDate: crtDate,
          isImportant: isImportant,
          taskId: DateTime.now(),
          completedOn: DateTime.now(),
        ),
      );
      _taskList = box.values.toList();
      _sortedTasksByDate = box.values
          .where((task) => task.deadLineDate == stringOfSelectedDate)
          .toList();
      _taskList =
          box.values.where((element) => element.creatorId == _userId).toList();
      notifyListeners();
    }
  }

  Future<bool> editTaskForFirebase(Task updatedTask) async {
    if (await hasInternet()) {
      hasInternetValue = true;
      final url = Uri.parse(
        'https://online-shopp-provider-default-rtdb.firebaseio.com/tasks/${updatedTask.taskIdOnFirebase}.json?auth=$_authToken',
      );
      try {
        final response = await http.patch(url,
            body: jsonEncode({
              'creatorId': _userId,
              'statusTaskForUpdate': updatedTask.statusTaskForUpdate,
              'taskId': updatedTask.taskId.toIso8601String(),
              'taskName': updatedTask.taskName,
              'createdTime': updatedTask.createdTime,
              'createdDate': updatedTask.createdDate.toIso8601String(),
              'deadLineDate': updatedTask.deadLineDate,
              'deadLineTime': updatedTask.deadLineTime,
              'completedOn': updatedTask.completedOn.toIso8601String(),
              'isImportant': updatedTask.isImportant,
              'isFinished': updatedTask.isFinished,
            }));
        if (response.statusCode == 200) {
          hasInternetValue = true;
          return true;
        } else {
          return false;
        }
      } catch (e) {
        rethrow;
      }
    } else {
      hasInternetValue = false;
      return true;
    }
  }

  void editTaskForDB(
      {required DateTime taskId, required Task editedTask}) async {
    var box = await Hive.openBox<Task>(boxName);
    _taskList = box.values.toList();

    Task toEditTask = _taskList.firstWhere((task) => task.taskId == taskId);
    final taskFirebaseId = toEditTask.taskIdOnFirebase;
    int editItemIndex = _taskList.indexOf(toEditTask);
    final Task lookEditedTask = Task(
      statusTaskForUpdate: hasInternetValue ? "edited" : "noEdited",
      creatorId: _userId,
      taskIdOnFirebase: taskFirebaseId,
      createdTime: editedTask.createdTime,
      deadLineDate: editedTask.deadLineDate,
      deadLineTime: editedTask.deadLineTime,
      taskName: editedTask.taskName,
      createdDate: editedTask.createdDate,
      taskId: taskId,
      completedOn: editedTask.completedOn,
      isImportant: editedTask.isImportant,
    );
    final response = await editTaskForFirebase(lookEditedTask);
    if (response) {
      await box.putAt(editItemIndex, lookEditedTask);
      _taskList = box.values.toList();
      _sortedTasksByDate = box.values
          .where((task) => task.deadLineDate == stringOfSelectedDate)
          .toList();
      _taskList =
          box.values.where((element) => element.creatorId == _userId).toList();
      notifyListeners();
    }
  }

  Future<bool> toggleTaskForFirebase(Task toggleTask, bool newValue) async {
    if (await hasInternet()) {
      final url = Uri.parse(
        'https://online-shopp-provider-default-rtdb.firebaseio.com/tasks/${toggleTask.taskIdOnFirebase}.json?auth=$_authToken',
      );
      try {
        final response = await http.patch(url,
            body: jsonEncode({
              'isFinished': newValue,
            }));
        if (response.statusCode == 200) {
          hasInternetValue = true;
          return true;
        } else {
          return false;
        }
      } catch (e) {
        rethrow;
      }
    } else {
      hasInternetValue = false;
      return true;
    }
  }

  void toggleTask(
      {required DateTime id,
      required String taskTitle,
      required DateTime completeOnDate,
      required bool newVal}) async {
    var box = await Hive.openBox<Task>(boxName);
    _taskList = box.values.toList();
    Task toModifyTask = _taskList.firstWhere(
      (item) => item.taskId == id && item.taskName == taskTitle,
    );
    toModifyTask.isFinished = newVal;
    toModifyTask.completedOn = completeOnDate;
    toModifyTask.statusTaskForUpdate =
        hasInternetValue ? "toggled" : "noToggle";
    final isToggled = await toggleTaskForFirebase(toModifyTask, newVal);
    if (isToggled) {
      int toModifyTaskIndex = _taskList.indexOf(toModifyTask);
      await box.putAt(toModifyTaskIndex, toModifyTask);
      _taskList = box.values.toList();
      notifyListeners();
    }
  }

  Future<bool> deleteTask(String idOnFirebase) async {
    if (await hasInternet()) {
      print("id =----delete -----$idOnFirebase");
      final url = Uri.parse(
        'https://online-shopp-provider-default-rtdb.firebaseio.com/tasks/$idOnFirebase.json?auth=$_authToken',
      );
      try {
        final response = await http.delete(url);
        print("deleting statusCode ========= ${response.statusCode}");
        if (response.statusCode >= 400) {
          return false;
        } else {
          return true;
        }
      } catch (e) {
        rethrow;
      }
    } else {
      return true;
    }
  }

  void removeSingleTask(
      {required DateTime id, required String taskTitle}) async {
    var box = await Hive.openBox<Task>(boxName);
    _taskList = box.values.toList();
    Task toDeleteTask = _taskList
        .firstWhere((task) => task.taskId == id && task.taskName == taskTitle);
    int toDeleteItemIndex = _taskList.indexOf(toDeleteTask);
    final isDelete = await deleteTask(toDeleteTask.taskIdOnFirebase!);
    if (isDelete) {
      await box.deleteAt(toDeleteItemIndex);
    }
    _sortedTasksByDate = box.values
        .where((task) => task.deadLineDate == stringOfSelectedDate)
        .toList();
    _taskList = box.values.toList();
    notifyListeners();
  }

  void deleteAllCompletedTasks() async {
    var box = await Hive.openBox<Task>(boxName);
    _taskList = box.values.toList();
    List<Task> toDeleteTasks =
        box.values.where((task) => task.isFinished == true).toList();

    for (Task task in toDeleteTasks) {
      if (toDeleteTasks.isNotEmpty) {
        final isDeleted = await deleteTask(task.taskIdOnFirebase.toString());
        if (isDeleted) {
          await box.deleteAt(_taskList.indexOf(task));
          _taskList = box.values.toList();
        }
        //updating list after every deletioin performed
      } else {
        return;
      }
    }
    _sortedTasksByDate = box.values
        .where((task) => task.deadLineDate == stringOfSelectedDate)
        .toList();
    _taskList = box.values.toList();
    notifyListeners();
  }
}
