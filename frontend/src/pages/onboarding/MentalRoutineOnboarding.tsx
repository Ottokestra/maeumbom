// src/pages/onboarding/MentalRoutineOnboarding.tsx
import React, { useState } from "react";
import "./MentalRoutineOnboarding.css";

type EntryCategory = {
  id: string;
  label: string;
  description?: string;
};

const ENTRY_CATEGORIES: EntryCategory[] = [
  {
    id: "simple-yn",
    label: "예/아니오로 간단히 응답",
    description: "빠르게 오늘 기분만 체크하고 싶어요."
  },
  {
    id: "condition",
    label: "오늘 컨디션 확인",
    description: "하루 컨디션을 조금 더 자세히 살펴볼게요."
  },
  {
    id: "routine",
    label: "루틴 점검",
    description: "생활 루틴과 패턴을 함께 돌아보고 싶어요."
  }
];

const MentalRoutineOnboarding: React.FC = () => {
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(
    null
  );

  const selectedCategory = ENTRY_CATEGORIES.find(
    (c) => c.id === selectedCategoryId
  );

  // TODO: 실제 설문 시작/네비게이션 로직 연결
  const handleStartNow = () => {
    if (!selectedCategory) return;

    // 예시: 선택한 카테고리 id에 따라 다른 설문으로 라우팅
    // navigate(`/survey/start?mode=${selectedCategory.id}`);
    console.log("선택한 시작 방식:", selectedCategory.id);
  };

  const handleStartLater = () => {
    // TODO: 나중에 할게요 눌렀을 때 처리 (예: 홈으로 이동)
    console.log("나중에 할게요 클릭");
  };

  return (
    <div className="mr-onboarding-page">
      <div className="mr-onboarding-card">
        {/* 상단 정보 영역 */}
        <div className="mr-onboarding-header">
          <div className="mr-onboarding-meta">마음봄 온보딩 1-4-1</div>
          <h1 className="mr-onboarding-title">
            오늘 마음과 루틴, 가볍게 점검해볼까요?
          </h1>
          <p className="mr-onboarding-description">
            5분 정도면 끝나는 간단한 설문이에요. 결과는 진단이 아니라 오늘의
            마음 상태를 돌아보는 참고 정보로만 사용돼요.
          </p>
          <p className="mr-onboarding-subcopy">
            오늘은 쉬어가기로 하셨어요. 언제든 다시 시작할 수 있어요.
          </p>
        </div>

        {/* 상단 메인 액션 버튼들 */}
        <div className="mr-onboarding-main-actions">
          <button
            type="button"
            className="mr-button mr-button--primary"
            onClick={handleStartNow}
            disabled={!selectedCategory}
          >
            지금 시작하기
          </button>
          <button
            type="button"
            className="mr-button mr-button--ghost"
            onClick={handleStartLater}
          >
            다음에 할게요
          </button>
        </div>

        {/* 카테고리 선택 영역 (MUKJA 스타일) */}
        <section className="mr-onboarding-category-section">
          <p className="mr-category-section-title">
            가볍게 체크해보고 싶은 날, 언제든 다시 시작할 수 있어요.
          </p>

          <div className="mr-category-chip-group">
            {ENTRY_CATEGORIES.map((category) => {
              const isSelected = category.id === selectedCategoryId;
              return (
                <button
                  key={category.id}
                  type="button"
                  className={
                    "mr-category-chip" +
                    (isSelected ? " mr-category-chip--selected" : "")
                  }
                  onClick={() => setSelectedCategoryId(category.id)}
                  aria-pressed={isSelected}
                >
                  <span className="mr-category-chip-label">
                    {category.label}
                  </span>
                  {category.description && (
                    <span className="mr-category-chip-desc">
                      {category.description}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </section>
      </div>
    </div>
  );
};

export default MentalRoutineOnboarding;
