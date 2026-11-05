import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const primaryGradient = LinearGradient(
  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const backgroundColor = Color(0xFFFAFAFA);

class Task {
  final String id;
  String title;
  String detail;
  bool isCompleted;
  DateTime createdAt;
  Color taskColor;

  Task({
    required this.id,
    required this.title,
    required this.detail,
    this.isCompleted = false,
    required this.createdAt,
    this.taskColor = const Color(0xFF667EEA),
  });
}

class TaskListProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  TaskListProvider() {
    final now = DateTime.now();
    _tasks.addAll([
      Task(
        id: '1',
        title: 'ЗАДАЧА 1',
        detail: 'Прийти на пересдачу',
        createdAt: now,
        taskColor: const Color(0xFF667EEA),
      ),
      Task(
        id: '2',
        title: 'ЗАДАЧА 2',
        detail: 'Сдать проект',
        createdAt: now,
        taskColor: const Color(0xFFF093FB),
      ),
    ]);
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(String id, String title, String detail) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].title = title;
      _tasks[index].detail = detail;
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
    }
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskListProvider(),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const TasksScreen(),
      ),
    ),
  );
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Consumer<TaskListProvider>(
                builder: (context, provider, _) {
                  final total = provider.tasks.length;
                  final completed = provider.tasks.where((t) => t.isCompleted).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Мои Задачи', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('$completed из $total завершено', style: const TextStyle(color: Colors.white70)),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Все'), icon: Icon(Icons.list)),
                  ButtonSegment(value: 1, label: Text('Выполнено'), icon: Icon(Icons.check_circle_outline)),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (newSelection) => setState(() => _selectedTab = newSelection.first),
              ),
            ),
            Expanded(
              child: Consumer<TaskListProvider>(
                builder: (context, provider, _) {
                  final tasks = _selectedTab == 0 ? provider.tasks : provider.tasks.where((t) => t.isCompleted).toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) => TaskCard(task: tasks[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => context.read<TaskListProvider>().toggleTaskCompletion(task.id),
        ),
        title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text(task.detail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)))),
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => context.read<TaskListProvider>().deleteTask(task.id)),
          ],
        ),
      ),
    );
  }
}

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});
  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final TextEditingController _title = TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _detail = TextEditingController(text: widget.task?.detail ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? 'Новая задача' : 'Редактировать')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _detail, decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.task == null) {
                  context.read<TaskListProvider>().addTask(Task(id: DateTime.now().toString(), title: _title.text, detail: _detail.text, createdAt: DateTime.now()));
                } else {
                  context.read<TaskListProvider>().updateTask(widget.task!.id, _title.text, _detail.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            )
          ],
        ),
      ),
    );
  }
}
