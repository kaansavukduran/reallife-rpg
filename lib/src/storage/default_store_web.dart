import 'browser_task_store.dart';
import 'task_store.dart';

Future<TaskStore> createDefaultStore() async => BrowserTaskStore();
