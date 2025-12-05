import { useMemo } from "react";
import "../styles/journey.css";

type JourneyStep = {
  id: string;
  title: string;
  eyebrow: string;
  description: string;
  milestones: string[];
  outcome: string;
};

const JOURNEY_STEPS: JourneyStep[] = [
  {
    id: "onboarding",
    title: "온보딩",
    eyebrow: "1단계",
    description: "첫 인사와 마음봄 소개로 서비스의 톤앤매너를 전달합니다.",
    milestones: [
      "마음봄 캐릭터와 기능을 가볍게 소개",
      "오늘의 감정 기록/호흡 가이드를 미리 보여주기",
      "소리와 애니메이션으로 편안한 첫인상 만들기",
    ],
    outcome: "사용자가 거부감 없이 다음 단계로 이동",
  },
  {
    id: "signup",
    title: "회원가입",
    eyebrow: "2단계",
    description: "소셜/간편 인증으로 1분 내 가입을 마무리합니다.",
    milestones: [
      "본인인증 혹은 구글/카카오/네이버 3초 로그인 제공",
      "약관 동의는 핵심 필수 + 선택 최소화",
      "초기 알림/맞춤 추천 온보딩 질문 3개 이내",
    ],
    outcome: "가입 완료 후 바로 홈으로 이동",
  },
  {
    id: "home",
    title: "홈 화면",
    eyebrow: "3단계",
    description: "가입 직후 오늘 해야 할 일을 한눈에 안내합니다.",
    milestones: [
      "오늘의 마음 날씨 카드 + 빠른 마음연습실 바로가기",
      "루틴/리포트 CTA와 어제 기록 리마인드",
      "봄이 캐릭터가 첫 대화 문장 제안",
    ],
    outcome: "이탈 없이 첫 체류 액션 발생",
  },
];

export function UserJourneyPage() {
  const timeline = useMemo(() => JOURNEY_STEPS, []);

  return (
    <div className="journey-page">
      <header className="journey-hero">
        <div>
          <p className="eyebrow">신규 사용자 여정</p>
          <h1>온보딩 → 회원가입 → 홈 진입 흐름을 한눈에</h1>
          <p className="subtitle">
            첫 만남부터 홈 화면까지 이어지는 핵심 경험을 단계별로 정리했어요. 팀 리뷰나
            데모에서 그대로 활용할 수 있는 체크리스트 형태입니다.
          </p>
        </div>
        <div className="hero-badge">
          <span className="badge-icon">✨</span>
          <div>
            <strong>핵심 목표</strong>
            <p>가입 전 이탈 최소화, 홈 진입 후 즉시 체류</p>
          </div>
        </div>
      </header>

      <section className="journey-grid">
        {timeline.map((step) => (
          <article key={step.id} className="journey-card">
            <div className="card-header">
              <span className="eyebrow">{step.eyebrow}</span>
              <h2>{step.title}</h2>
              <p className="card-desc">{step.description}</p>
            </div>
            <ul className="milestone-list">
              {step.milestones.map((item) => (
                <li key={item}>
                  <span className="dot" aria-hidden />
                  <div>{item}</div>
                </li>
              ))}
            </ul>
            <div className="outcome-box">
              <span className="label">다음 단계 결과</span>
              <p>{step.outcome}</p>
            </div>
          </article>
        ))}
      </section>

      <section className="cta-panel">
        <div>
          <p className="eyebrow">연결된 경험</p>
          <h3>온보딩 여정과 바로 이어지는 마음연습실</h3>
          <p className="card-desc">
            가입 직후 홈에서 노출될 마음연습실을 시나리오별로 테스트해보세요.
            관계에 맞는 상황을 고르면 1-3단계 진행과 엔딩 4컷을 바로 확인할 수 있어요.
          </p>
        </div>
        <a className="primary-link" href="/practice">
          마음연습실로 이동하기 →
        </a>
      </section>
    </div>
  );
}
