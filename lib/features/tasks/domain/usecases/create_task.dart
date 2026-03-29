import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTask {
  const CreateTask(this._repository);
  final TaskRepository _repository;

  /// The 2-second simulated network delay lives in the repository impl,
  /// keeping this use case clean and instantly testable.
  Future<void> call(TaskEntity task) => _repository.createTask(task);
}
