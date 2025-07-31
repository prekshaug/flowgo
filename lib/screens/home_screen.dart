import 'package:flutter/material.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTasks = const []});

  final List<Task> initialTasks;


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.initialTasks);
  }


  void _addNewTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Image.asset('assets/images/flowgo_logo.png', height: 32),
          const SizedBox(width: 8),
          const Text('FlowGo Planner'),
        ],
      ),),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (ctx, index) {
          final task = _tasks[index];
          return ListTile(
            leading: Icon(Icons.event_note),
            title: Text(task.title),
            subtitle: Text(
              '${task.from} → ${task.to} • ${task.startTime.hour}:${task.startTime.minute.toString().padLeft(2, '0')}',


            ),
            trailing: task.needsRoute ? Icon(Icons.navigation) : null,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TaskDetailScreen(task: task),
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(onAdd: _addNewTask),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

    );
  }


}
