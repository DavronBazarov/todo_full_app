import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timer_snackbar/timer_snackbar.dart';

import '../constants.dart';
import '../models/task.dart';
import '../providers/auth.dart';
import '../providers/task_provider.dart';

class CompletedTasksScreen extends StatelessWidget {
   CompletedTasksScreen({Key? key}) : super(key: key);

  static const routeName = 'completed_task-screen';

  @override
  Widget build(BuildContext context) {
    final Color wholeColor = Colors.yellow[50]!;

    List<Task> completedTaskList = Provider.of<TaskProvider>(
      context,
    ).getCompletedTasksList;
    return Scaffold(

      appBar: AppBar(
        title: const Text('All Completed Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
              Provider.of<Auth>(context, listen: false).logOut();
            },
            icon: const Icon(Icons.logout_outlined, size: 30,),
          ),
         const SizedBox(width: 15)
        ],
      ),
      body: Column(children: [
        Expanded(
          //height: 200,
          child: ListView.separated(
              separatorBuilder: (context, index) {
                return Divider(
                  height: 1,
                  endIndent: 10,
                  indent: 10,
                  thickness: 1,
                  color: Theme.of(context).primaryColor,
                );
              },
              itemCount: completedTaskList.length,
              itemBuilder: (_, index) {
                String taskCompletedOn = DateFormat('dd-MM-yyyy')
                    .format(completedTaskList[index].completedOn);
                return ListTile(
                  tileColor: wholeColor,
                  contentPadding:
                      const EdgeInsets.only(left: 10, bottom: 0, top: 0),
                  hoverColor: Colors.green,
                  dense: true,
                  title: Text(
                    completedTaskList[index].taskName,
                    style: kTaskNameStyle,
                  ),
                  subtitle: Text('Completed On -> $taskCompletedOn',
                      style: kCompleteTaskDateStyle),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      Provider.of<TaskProvider>(context, listen: false)
                          .removeSingleTask(
                              id: completedTaskList[index].taskId,
                              taskTitle: completedTaskList[index].taskName);
                    },
                  ),
                );
              }),
        ),
      ]),
      bottomNavigationBar: BottomAppBar(
        color: Colors.red,
        child: TextButton(
          onPressed: () {
            if (completedTaskList.isNotEmpty) {
              timerSnackbar(
                context: context,
                contentText: "Completed tasks will remove!.",
                afterTimeExecute: () {
                  Provider.of<TaskProvider>(context, listen: false)
                      .deleteAllCompletedTasks();
                  Navigator.pop(context);
                },
                second: 5,
              );
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No New Task Completed !',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
            }
          },
          child: const Text(
            'Clear All',
            style: kDelteAllTextStyle,
          ),
        ),
      ),
    );
  }
}
