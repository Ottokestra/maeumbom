import '../../../data/dtos/routine_recommendations/routine_recommendation_response.dart';
import '../../../ui/characters/app_characters.dart';
import '../../../core/utils/emotion_mapper.dart';
import '../../../core/utils/logger.dart';

/// 루틴 추천 데이터에서 주요 감정에 맞는 루틴을 추출하는 서비스
class RoutineExtractor {
  /// 주간 루틴 추천 데이터에서 주요 감정에 맞는 루틴 제목들을 추출
  ///
  /// [recommendations]: TB_ROUTINE_RECOMMENDATIONS 테이블의 데이터 목록
  /// [primaryEmotion]: 주요 감정 (EmotionId)
  ///
  /// Returns: 추출된 루틴 제목 목록 (최대 3개, 중복 제거됨)
  static List<String> extractRoutinesForEmotion({
    required List<RoutineRecommendationResponse> recommendations,
    required EmotionId? primaryEmotion,
  }) {
    if (primaryEmotion == null || recommendations.isEmpty) {
      appLogger.d('🟡 [RoutineExtractor] No primary emotion or empty recommendations');
      return [];
    }

    // 1. EmotionId를 한글명으로 변환
    final primaryEmotionKorean = EmotionMapper.toKoreanName(
      EmotionMapper.toCode(primaryEmotion) ?? ''
    );

    if (primaryEmotionKorean == null) {
      appLogger.d('🟡 [RoutineExtractor] Could not convert emotion to Korean: $primaryEmotion');
      return [];
    }

    appLogger.d('🔵 [RoutineExtractor] Extracting routines for emotion: $primaryEmotionKorean ($primaryEmotion)');

    // 2. 루틴 제목을 저장할 Set (중복 제거)
    final Set<String> routineTitles = {};

    // 3. recommendations를 순회하며 PRIMARY_EMOTION이 일치하는 항목 찾기
    for (final recommendation in recommendations) {
      // PRIMARY_EMOTION이 일치하는지 확인
      if (recommendation.primaryEmotion == primaryEmotionKorean) {
        // ROUTINES JSON에서 루틴 제목 추출
        final routines = recommendation.routines;
        
        if (routines != null && routines.isNotEmpty) {
          for (final routine in routines) {
            // routine이 Map 형태인지 확인
            if (routine is Map<String, dynamic>) {
              final title = routine['title'] as String?;
              if (title != null && title.isNotEmpty) {
                routineTitles.add(title);
                
                // 최대 3개까지만 수집
                if (routineTitles.length >= 3) {
                  break;
                }
              }
            }
          }
        }
      }

      // 이미 3개를 수집했으면 중단
      if (routineTitles.length >= 3) {
        break;
      }
    }

    // 4. PRIMARY_EMOTION이 정확히 일치하는 루틴이 없으면,
    //    EMOTION_SUMMARY에서 해당 감정이 포함된 항목 찾기 (fallback)
    if (routineTitles.isEmpty) {
      appLogger.d('🟡 [RoutineExtractor] No exact match, trying fallback with EMOTION_SUMMARY');
      
      for (final recommendation in recommendations) {
        final emotionSummary = recommendation.emotionSummary;
        
        if (emotionSummary != null && emotionSummary.containsKey(primaryEmotionKorean)) {
          final routines = recommendation.routines;
          
          if (routines != null && routines.isNotEmpty) {
            for (final routine in routines) {
              if (routine is Map<String, dynamic>) {
                final title = routine['title'] as String?;
                if (title != null && title.isNotEmpty) {
                  routineTitles.add(title);
                  
                  if (routineTitles.length >= 3) {
                    break;
                  }
                }
              }
            }
          }
        }

        if (routineTitles.length >= 3) {
          break;
        }
      }
    }

    final result = routineTitles.toList();
    appLogger.d('🟢 [RoutineExtractor] Extracted ${result.length} routines: $result');
    
    return result;
  }
}

