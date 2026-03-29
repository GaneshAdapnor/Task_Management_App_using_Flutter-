import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/task_local_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/update_task.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

/// Overridden in main() with the real instance (avoids async in providers).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override in ProviderScope'),
);

// ─── Data layer ───────────────────────────────────────────────────────────────

final _dataSourceProvider = Provider<TaskLocalDataSource>(
  (_) => TaskLocalDataSourceImpl.instance,
);

final _repositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.read(_dataSourceProvider)),
);

// ─── Use cases ────────────────────────────────────────────────────────────────

final getTasksProvider =
    Provider((ref) => GetTasks(ref.read(_repositoryProvider)));

final createTaskProvider =
    Provider((ref) => CreateTask(ref.read(_repositoryProvider)));

final updateTaskProvider =
    Provider((ref) => UpdateTask(ref.read(_repositoryProvider)));

final deleteTaskProvider =
    Provider((ref) => DeleteTask(ref.read(_repositoryProvider)));
