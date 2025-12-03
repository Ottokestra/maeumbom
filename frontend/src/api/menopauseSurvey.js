// frontend/src/api/menopauseSurvey.js

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";

function buildAuthHeaders() {
  const accessToken = localStorage.getItem("access_token");

  const headers = {
    "Content-Type": "application/json",
  };

  if (accessToken) {
    headers["Authorization"] = `Bearer ${accessToken}`;
  }

  return headers;
}

/**
 * 갱년기 설문 결과 제출
 */
export async function submitMenopauseSurvey(payload) {
  const token = localStorage.getItem("access_token");

  const res = await fetch(`${API_BASE_URL}/api/menopause-survey/submit`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(payload),
  });

  if (res.status === 401 || res.status === 403) {
    throw new Error("로그인이 만료됐거나 권한이 없습니다. 다시 로그인해 주세요.");
  }

  if (!res.ok) {
    const errData = await res.json().catch(() => ({}));
    throw new Error(errData.detail || "설문 저장 중 서버 오류가 발생했습니다.");
  }

  return res.json();
}
/**
 * 로그인 직후, 이 계정이 갱년기 설문을 이미 했는지 확인하는 용도
 * - 백엔드에 /api/menopause-survey/status 가 있으면 거기로 조회
 * - 없거나 에러면 기본값 { completed: false }만 돌려준다
 */
export async function getMenopauseSurveyStatus() {
  const accessToken = localStorage.getItem("access_token");
  if (!accessToken) {
    // 로그인 안 되어 있으면 무조건 미완료로 간주
    return { completed: false };
  }

  try {
    const response = await fetch(
      `${API_BASE_URL}/api/menopause-survey/status`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    if (!response.ok) {
      // 404 / 403 등 오류가 떠도 앱이 죽지 않도록 기본값만 반환
      console.warn(
        "[menopauseSurvey] status 요청 실패:",
        response.status
      );
      return { completed: false };
    }

    // 백엔드에서 { completed: true/false, ... } 형태를 돌려준다고 가정
    return await response.json();
  } catch (err) {
    console.error("[menopauseSurvey] status 요청 에러:", err);
    return { completed: false };
  }
}
