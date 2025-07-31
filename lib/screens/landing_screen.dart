import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flow_go/screens/add_task_screen.dart';
import 'package:flow_go/models/task.dart';
import 'package:flow_go/screens/home_screen.dart';


List<Task> _tasks = [];

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/flowgo.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: SafeArea(
        child: Center(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            // Section 1: Animation
            const SizedBox(height: 40),
            if (_controller.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            else
              const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 40),

            const SizedBox(height: 16),

            // Section 3: Secondary CTA
          ElevatedButton(
            onPressed: () async {
              final Task? newTask = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(
                    onAdd: (task) {}, // still required, but unused here
                  ),
                ),
              );

              if (newTask != null) {
                setState(() {
                  _tasks.add(newTask); // ✅ This ensures the task is stored
                });
              }
            },
            child: const Text('Create Plan'),
          ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(initialTasks: _tasks),
                ),
              );
            },
            child: const Text("View My Plans"),
          ),




        ],
        ),
      ),

      ),
    );

  }
}


