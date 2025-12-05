import { useMemo, useState } from "react";
import "../styles/journey.css";

type Relationship = {
  id: string;
  label: string;
  summary: string;
};

type Scenario = {
  id: string;
  title: string;
  context: string;
  steps: string[];
  endingCuts: string[];
};

const RELATIONSHIPS: Relationship[] = [
  { id: "partner", label: "연인/배우자", summary: "감정이 쌓여 걱정이 될 때" },
  { id: "family", label: "부모님/가족", summary: "가족과의 대화가 서툴 때" },
  { id: "work", label: "직장", summary: "동료/리더와 협업 스트레스" },
  { id: "friend", label: "친구", summary: "친구와의 서운함 조율" },
];

const SCENARIOS: Record<string, Scenario[]> = {
  partner: [
    {
      id: "slow-talk",
      title: "서로 다른 속도를 이해하기",
      context: "상대방이 답장이 느려 서운했던 상황을 재구성합니다.",
      steps: [
        "느린 답장이 주는 감정 언어를 적어 보기",
        "상대방 상황을 추측하기 전에 사실만 정리",
        "내가 원하는 소통 속도 제안하기",
      ],
      endingCuts: [
        "1컷: 답장을 기다리며 쌓인 감정이 말풍선으로 나타나요",
        "2컷: 서로의 하루 리듬을 공유하며 이해가 생겨요",
        "3컷: 다음 대화 약속 시간을 같이 정해요",
        "4컷: 답장 속도가 느려도 괜찮다는 표정으로 마무리",
      ],
    },
  ],
  family: [
    {
      id: "dinner",
      title: "저녁 식사 자리에서 꺼내는 말",
      context: "가족과 마음을 나누기 어려운 저녁 식탁을 연습합니다.",
      steps: [
        "밥상머리 대화에서 피하고 싶었던 주제 적기",
        "감정 대신 상황을 먼저 묘사하는 문장 만들기",
        "상대방 반응을 기다리는 침묵도 연습하기",
      ],
      endingCuts: [
        "1컷: 숟가락을 내려놓고 호흡을 고르는 장면",
        "2컷: 내 마음을 짧게 전하는 말풍선",
        "3컷: 가족이 고개를 끄덕이며 듣고 있어요",
        "4컷: 밥상 위 온기가 도는 모습으로 마무리",
      ],
    },
  ],
  work: [
    {
      id: "feedback",
      title: "피드백 자리에서 감정 지키기",
      context: "팀 회의에서 즉흥 피드백이 주는 부담을 다룹니다.",
      steps: [
        "불편했던 발언을 구체적으로 한 줄 기록",
        "내가 듣고 싶은 문장과 듣기 어려운 문장 분리",
        "회의 전 사전 아젠다 요청 메시지 작성",
      ],
      endingCuts: [
        "1컷: 회의실 입구에서 깊은 숨을 들이마셔요",
        "2컷: 메모로 정리된 아젠다가 테이블 위에 놓여요",
        "3컷: 동료와 시선을 맞추며 대화를 이어가요",
        "4컷: 회의 후 가벼워진 표정으로 일정을 정리",
      ],
    },
  ],
  friend: [
    {
      id: "plan-change",
      title: "계획 변경에 서운함 전하기",
      context: "약속을 자주 미루는 친구에게 마음을 전하는 법을 연습합니다.",
      steps: [
        "지난 변경 사례를 감정 대신 사실로 적기",
        "서운함을 낱말 카드처럼 짧게 표현",
        "앞으로의 약속 규칙을 함께 정하는 제안 작성",
      ],
      endingCuts: [
        "1컷: 달력 위 취소 스티커를 정리하며 한숨",
        "2컷: 친구에게 보내는 짧은 메시지 초안",
        "3컷: 함께 웃으며 새로운 약속을 잡아요",
        "4컷: 서로의 캘린더에 초대장이 반짝여요",
      ],
    },
  ],
};

export function PracticeStudioPage() {
  const [relationship, setRelationship] = useState<Relationship>(RELATIONSHIPS[0]);
  const scenarios = useMemo(() => SCENARIOS[relationship.id] || [], [relationship.id]);
  const [selectedScenario, setSelectedScenario] = useState<Scenario>(scenarios[0]);

  return (
    <div className="journey-page">
      <header className="journey-hero">
        <div>
          <p className="eyebrow">마음연습실</p>
          <h1>관계별 시나리오를 고르고 1, 2, 3단계와 엔딩 4컷을 확인하세요</h1>
          <p className="subtitle">
            실제 서비스 흐름처럼 관계를 먼저 선택하고, 어울리는 상황을 택해 연습 단계를 바로 확인할 수 있도록 구성했습니다.
          </p>
        </div>
      </header>

      <section className="relationship-row">
        {RELATIONSHIPS.map((item) => (
          <button
            key={item.id}
            className={`pill ${item.id === relationship.id ? "active" : ""}`}
            onClick={() => {
              setRelationship(item);
              const firstScenario = (SCENARIOS[item.id] || [])[0];
              if (firstScenario) {
                setSelectedScenario(firstScenario);
              }
            }}
          >
            <strong>{item.label}</strong>
            <span>{item.summary}</span>
          </button>
        ))}
      </section>

      <section className="scenario-grid">
        {scenarios.map((scenario) => (
          <article
            key={scenario.id}
            className={`scenario-card ${selectedScenario?.id === scenario.id ? "active" : ""}`}
            onClick={() => setSelectedScenario(scenario)}
          >
            <p className="eyebrow">{relationship.label}</p>
            <h3>{scenario.title}</h3>
            <p className="card-desc">{scenario.context}</p>
          </article>
        ))}
      </section>

      {selectedScenario && (
        <section className="scenario-detail">
          <div className="steps">
            <h4>1-3단계 진행</h4>
            <ol>
              {selectedScenario.steps.map((step, index) => (
                <li key={step}>
                  <span className="step-number">{index + 1}</span>
                  <div>
                    <p className="step-title">Step {index + 1}</p>
                    <p>{step}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>

          <div className="ending">
            <div className="ending-head">
              <div>
                <p className="eyebrow">엔딩</p>
                <h4>4컷으로 미리 보는 결말</h4>
              </div>
              <span className="ending-label">완료 후 예상 감정</span>
            </div>
            <div className="ending-cuts">
              {selectedScenario.endingCuts.map((cut) => (
                <div key={cut} className="cut-box">
                  <p>{cut}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}
    </div>
  );
}
