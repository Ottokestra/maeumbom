import { useEffect, useMemo, useState } from "react";
import { useMenopauseQuestions } from "../hooks/useMenopauseQuestions";
import "../styles/menopauseAdmin.css";

export function MenopauseQuestionAdminPage() {
  const {
    questions,
    loading,
    error,
    filters,
    submitting,
    seeding,
    setFilter,
    refresh,
    createQuestion,
    updateQuestion,
    deleteQuestion,
    seedDefaults,
    defaultForm,
  } = useMenopauseQuestions();

  const [formState, setFormState] = useState(defaultForm);
  const [editingId, setEditingId] = useState(null);

  useEffect(() => {
    setFormState(defaultForm);
    setEditingId(null);
  }, [defaultForm]);

  const handleEdit = (item) => {
    setEditingId(item.id);
    setFormState({
      gender: item.gender || "FEMALE",
      code: item.code || "",
      orderNo: item.orderNo || 1,
      questionText: item.questionText || "",
      riskWhenYes: item.riskWhenYes || "",
      positiveLabel: item.positiveLabel || "",
      negativeLabel: item.negativeLabel || "",
      characterKey: item.characterKey || "",
      isActive: item.isActive ?? true,
    });
  };

  const resetForm = () => {
    setEditingId(null);
    setFormState(defaultForm);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (editingId) {
      await updateQuestion(editingId, formState);
    } else {
      await createQuestion(formState);
    }
    resetForm();
  };

  const handleDelete = async (id) => {
    if (!id) return;
    if (confirm("이 문항을 삭제할까요?")) {
      await deleteQuestion(id);
    }
  };

  const handleSeed = async () => {
    const ok = await seedDefaults();
    if (ok) {
      alert("기본 문항이 등록되었습니다.");
    }
  };

  const activeLabel = useMemo(() => {
    if (filters.isActive === "all") return "전체";
    if (filters.isActive === "active") return "활성";
    return "비활성";
  }, [filters.isActive]);

  return (
    <div className="admin-page">
      <header className="admin-header">
        <div>
          <p className="eyebrow">관리자 도구 · 갱년기 자가테스트</p>
          <h1>설문 문항 관리</h1>
          <p className="description">
            성별/활성 상태 필터를 이용해 문항을 정렬하고, 우측 패널에서 새 문항을 추가하거나 기존 문항을
            수정하세요. (서비스 공개 전 헤더 내 관리자 메뉴에서만 접근하도록 주석 처리해둘 수 있습니다.)
          </p>
        </div>
        <div className="header-actions">
          <button className="ghost-btn" onClick={() => refresh()} disabled={loading}>
            새로고침
          </button>
          <button className="primary-btn" onClick={handleSeed} disabled={seeding}>
            {seeding ? "등록 중" : "기본 문항 시드 등록"}
          </button>
        </div>
      </header>

      <div className="admin-content">
        <section className="list-panel">
          <div className="filter-row">
            <div className="filter-group">
              <label htmlFor="gender-filter">성별</label>
              <select
                id="gender-filter"
                value={filters.gender}
                onChange={(e) => setFilter("gender", e.target.value)}
              >
                <option value="ALL">전체</option>
                <option value="FEMALE">여성</option>
                <option value="MALE">남성</option>
              </select>
            </div>
            <div className="filter-group">
              <label htmlFor="active-filter">활성 여부</label>
              <select
                id="active-filter"
                value={filters.isActive}
                onChange={(e) => setFilter("isActive", e.target.value)}
              >
                <option value="all">전체</option>
                <option value="active">활성</option>
                <option value="inactive">비활성</option>
              </select>
            </div>
            <div className="filter-chip">{activeLabel}</div>
          </div>

          {loading && <div className="muted">문항을 불러오는 중...</div>}
          {error && <div className="error-text">{error}</div>}

          <div className="table-wrapper">
            <table className="question-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>성별</th>
                  <th>코드</th>
                  <th>문항</th>
                  <th>Yes 위험</th>
                  <th>감정 캐릭터</th>
                  <th>활성</th>
                  <th>액션</th>
                </tr>
              </thead>
              <tbody>
                {questions.map((item) => (
                  <tr key={item.id || item.code}>
                    <td>{item.orderNo}</td>
                    <td>{item.gender}</td>
                    <td>{item.code}</td>
                    <td className="question-text">{item.questionText}</td>
                    <td>{item.riskWhenYes || "-"}</td>
                    <td>{item.characterKey || "-"}</td>
                    <td>
                      <span className={`badge ${item.isActive ? "on" : "off"}`}>
                        {item.isActive ? "ON" : "OFF"}
                      </span>
                    </td>
                    <td className="actions">
                      <button className="ghost-btn" onClick={() => handleEdit(item)}>
                        수정
                      </button>
                      <button className="danger-btn" onClick={() => handleDelete(item.id)}>
                        삭제
                      </button>
                    </td>
                  </tr>
                ))}
                {!loading && questions.length === 0 && (
                  <tr>
                    <td colSpan={8} className="muted">
                      아직 문항이 없어요. 오른쪽에서 새 문항을 추가해 주세요.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

        <aside className="form-panel">
          <div className="form-card">
            <div className="form-header">
              <div>
                <p className="eyebrow">{editingId ? "문항 수정" : "새 문항 추가"}</p>
                <h2>{editingId ? "선택한 문항을 수정합니다" : "갱년기 자가테스트 문항"}</h2>
              </div>
              {editingId && (
                <button className="ghost-btn" onClick={resetForm}>
                  새로 작성
                </button>
              )}
            </div>

            <form className="question-form" onSubmit={handleSubmit}>
              <div className="form-row">
                <label>성별</label>
                <select
                  value={formState.gender}
                  onChange={(e) => setFormState((prev) => ({ ...prev, gender: e.target.value }))}
                >
                  <option value="FEMALE">여성</option>
                  <option value="MALE">남성</option>
                </select>
              </div>

              <div className="form-row two-col">
                <div>
                  <label>코드</label>
                  <input
                    value={formState.code}
                    onChange={(e) => setFormState((prev) => ({ ...prev, code: e.target.value }))}
                    placeholder="예: MENO_01"
                    required
                  />
                </div>
                <div>
                  <label>순서</label>
                  <input
                    type="number"
                    min={1}
                    value={formState.orderNo}
                    onChange={(e) =>
                      setFormState((prev) => ({ ...prev, orderNo: Number(e.target.value) }))
                    }
                  />
                </div>
              </div>

              <div className="form-row">
                <label>문항 내용</label>
                <textarea
                  value={formState.questionText}
                  onChange={(e) =>
                    setFormState((prev) => ({ ...prev, questionText: e.target.value }))
                  }
                  placeholder="예: 일의 집중력이나 기억력이 예전 같지 않다고 느낀다."
                  required
                />
              </div>

              <div className="form-row">
                <label>위험 설명(Yes)</label>
                <input
                  value={formState.riskWhenYes}
                  onChange={(e) =>
                    setFormState((prev) => ({ ...prev, riskWhenYes: e.target.value }))
                  }
                  placeholder="예: 예라고 답하면 위험군"
                />
              </div>

              <div className="form-row two-col">
                <div>
                  <label>긍정 라벨</label>
                  <input
                    value={formState.positiveLabel}
                    onChange={(e) =>
                      setFormState((prev) => ({ ...prev, positiveLabel: e.target.value }))
                    }
                  />
                </div>
                <div>
                  <label>부정 라벨</label>
                  <input
                    value={formState.negativeLabel}
                    onChange={(e) =>
                      setFormState((prev) => ({ ...prev, negativeLabel: e.target.value }))
                    }
                  />
                </div>
              </div>

              <div className="form-row two-col">
                <div>
                  <label>캐릭터 키</label>
                  <input
                    value={formState.characterKey}
                    onChange={(e) =>
                      setFormState((prev) => ({ ...prev, characterKey: e.target.value }))
                    }
                    placeholder="예: PEACH_WORRY"
                  />
                </div>
                <div className="checkbox-row">
                  <label htmlFor="is-active">활성화</label>
                  <input
                    id="is-active"
                    type="checkbox"
                    checked={formState.isActive}
                    onChange={(e) =>
                      setFormState((prev) => ({ ...prev, isActive: e.target.checked }))
                    }
                  />
                </div>
              </div>

              <div className="form-actions">
                <button type="submit" className="primary-btn" disabled={submitting}>
                  {submitting ? "저장 중" : editingId ? "수정하기" : "추가하기"}
                </button>
                <button type="button" className="ghost-btn" onClick={resetForm}>
                  취소
                </button>
              </div>
            </form>
          </div>
        </aside>
      </div>
    </div>
  );
}
