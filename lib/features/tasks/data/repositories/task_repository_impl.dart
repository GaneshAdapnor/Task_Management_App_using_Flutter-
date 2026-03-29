import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// Implements the domain contract.
/// The simulated 2-second delay lives here — it represents the "network call"
/// boundary. Keeping it in the repository means the use cases remain instant
/// and pure, and we can remove the delay or replace it with a real API call
/// in exactly one place.
class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._dataSource);
  final TaskLocalDataSource _dataSource;

  static const _simulatedDelay = Duration(seconds: 2);

  @override
  Future<List<TaskEntity>> getTasks() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> createTask(TaskEntity task) async {
    await Future.delayed(_simulatedDelay);
    await _dataSource.insert(TaskModel.fromEntity(task));
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    await Future.delayed(_simulatedDelay);
    await _dataSource.update(TaskModel.fromEntity(task));
  }

  @override
  Future<void> deleteTask(String id) async {
    // Delete is instant — no delay for destructive actions.
    await _dataSource.delete(id);
  }
}
