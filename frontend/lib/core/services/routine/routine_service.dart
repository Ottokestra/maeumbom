import '../../../data/models/routine/routine_recommendation.dart';
import '../../../data/repository/routine/routine_repository.dart';

/// 루틴 추천 비즈니스 로직 서비스
class RoutineService {
  RoutineService(this._repository);

  final RoutineRepository _repository;

  /// 최근 루틴 추천 데이터 조회
  /// 
  /// 하루 전(어제) 데이터 우선 조회, 없으면 가장 최근 데이터 반환
  /// 데이터가 없으면 빈 routines를 가진 객체 반환
  Future<RoutineRecommendation> getLatestRecommendation() async {
    try {
      return await _repository.getLatestRecommendation();
    } catch (e) {
      // 에러 발생 시 빈 데이터 반환 (사용자 경험 유지)
      return const RoutineRecommendation(routines: []);
    }
  }

  /// 루틴 데이터가 유효한지 확인
  bool hasValidRoutines(RoutineRecommendation? recommendation) {
    return recommendation != null && recommendation.routines.isNotEmpty;
  }
}

