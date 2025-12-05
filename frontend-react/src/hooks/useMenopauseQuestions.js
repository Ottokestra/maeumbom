import { useCallback, useEffect, useMemo, useState } from "react";
import { apiClient } from "../api/client";

const defaultForm = {
  gender: "FEMALE",
  code: "",
  orderNo: 1,
  questionText: "",
  riskWhenYes: "",
  positiveLabel: "예",
  negativeLabel: "아니오",
  characterKey: "",
  isActive: true,
};

const toClient = (item = {}) => ({
  id: item.id,
  gender: item.gender,
  code: item.code,
  orderNo: item.order_no,
  questionText: item.question_text,
  riskWhenYes: item.risk_when_yes,
  positiveLabel: item.positive_label,
  negativeLabel: item.negative_label,
  characterKey: item.character_key,
  isActive: item.is_active,
});

const toServer = (item) => ({
  gender: item.gender,
  code: item.code,
  order_no: Number(item.orderNo) || 0,
  question_text: item.questionText,
  risk_when_yes: item.riskWhenYes,
  positive_label: item.positiveLabel,
  negative_label: item.negativeLabel,
  character_key: item.characterKey,
  is_active: item.isActive,
});

export function useMenopauseQuestions() {
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ gender: "ALL", isActive: "all" });
  const [submitting, setSubmitting] = useState(false);
  const [seeding, setSeeding] = useState(false);

  const fetchQuestions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = {};
      if (filters.gender && filters.gender !== "ALL") {
        params.gender = filters.gender;
      }
      if (filters.isActive !== "all") {
        params.is_active = filters.isActive === "active";
      }
      const resp = await apiClient.get("/menopause/questions", { params });
      const list = Array.isArray(resp.data) ? resp.data.map(toClient) : [];
      setQuestions(list);
    } catch (err) {
      console.error(err);
      setError("설문 문항을 불러오지 못했어요.");
    } finally {
      setLoading(false);
    }
  }, [filters.gender, filters.isActive]);

  const handleCreate = useCallback(
    async (payload) => {
      setSubmitting(true);
      try {
        await apiClient.post("/menopause/questions", toServer(payload));
        await fetchQuestions();
      } catch (err) {
        console.error(err);
        setError("문항을 추가하는 중 문제가 발생했어요.");
      } finally {
        setSubmitting(false);
      }
    },
    [fetchQuestions]
  );

  const handleUpdate = useCallback(
    async (id, payload) => {
      if (!id) return;
      setSubmitting(true);
      try {
        await apiClient.put(`/menopause/questions/${id}`, toServer(payload));
        await fetchQuestions();
      } catch (err) {
        console.error(err);
        setError("문항을 수정하는 중 문제가 발생했어요.");
      } finally {
        setSubmitting(false);
      }
    },
    [fetchQuestions]
  );

  const handleDelete = useCallback(
    async (id) => {
      if (!id) return;
      setSubmitting(true);
      try {
        await apiClient.delete(`/menopause/questions/${id}`);
        await fetchQuestions();
      } catch (err) {
        console.error(err);
        setError("문항을 삭제하는 중 문제가 발생했어요.");
      } finally {
        setSubmitting(false);
      }
    },
    [fetchQuestions]
  );

  const handleSeedDefaults = useCallback(async () => {
    setSeeding(true);
    try {
      await apiClient.post("/menopause/questions/seed-defaults");
      await fetchQuestions();
      return true;
    } catch (err) {
      console.error(err);
      setError("기본 문항을 등록하지 못했어요.");
      return false;
    } finally {
      setSeeding(false);
    }
  }, [fetchQuestions]);

  const filtered = useMemo(() => {
    return [...questions].sort((a, b) => (a.orderNo ?? 0) - (b.orderNo ?? 0));
  }, [questions]);

  useEffect(() => {
    fetchQuestions();
  }, [fetchQuestions]);

  const updateFilter = useCallback((key, value) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  }, []);

  return {
    questions: filtered,
    loading,
    error,
    filters,
    submitting,
    seeding,
    setFilter: updateFilter,
    refresh: fetchQuestions,
    createQuestion: handleCreate,
    updateQuestion: handleUpdate,
    deleteQuestion: handleDelete,
    seedDefaults: handleSeedDefaults,
    defaultForm,
  };
}
