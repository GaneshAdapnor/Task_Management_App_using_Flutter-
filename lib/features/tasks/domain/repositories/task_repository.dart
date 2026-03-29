import '../entities/task_entity.dart';

/// The boundary between domain and data.
/// The domain never knows whether tasks come from SQLite, an API, or a mock.
abstract interface class TaskRepository {
  Future<List<TaskEntity>> getTasks();
  Future<void> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String id);
}
