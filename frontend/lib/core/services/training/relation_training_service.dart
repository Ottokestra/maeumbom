import '../../../data/models/training/relation_training.dart';
import '../../../data/repository/training/relation_training_repository.dart';

class RelationTrainingService {
  final RelationTrainingRepository _repository;

  RelationTrainingService(this._repository);

  Future<ScenarioStartResponse> startScenario(int scenarioId) async {
    return _repository.startScenario(scenarioId);
  }

  Future<List<TrainingScenario>> getScenarios() async {
    return _repository.getScenarios();
  }

  Future<ScenarioProgressResponse> progressScenario({
    required int scenarioId,
    required int currentNodeId,
    required String selectedOptionCode,
    String currentPath = '',
  }) async {
    // Backend expects full path including new choice? 
    // Or just strictly history?
    // Based on previous debugging, we were appending. 
    // Let's assume (CurrentPath + Selection) is the logic we want to maintain.
    
    final newPath = currentPath + selectedOptionCode;
    
    return _repository.progressScenario(
      scenarioId: scenarioId,
      currentNodeId: currentNodeId,
      selectedOptionCode: selectedOptionCode,
      currentPath: newPath,
    );
  }
}
