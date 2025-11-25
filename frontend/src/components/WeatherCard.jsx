import { useEffect, useState } from "react";

/**
 * 현재 위치 기반 날씨 카드
 * - 브라우저 geolocation → /api/service/weather/current/location 호출
 * - 권한 거부/실패 시 Seoul 로 fallback
 */
export default function WeatherCard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [source, setSource] = useState("detecting"); // 'geo' | 'fallback'

  useEffect(() => {
    const fetchByCoords = async (lat, lon) => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(
          `http://localhost:8000/api/service/weather/current/location?lat=${lat}&lon=${lon}`
        );
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        setData(json);
        setSource("geo");
      } catch (e) {
        console.error("위치 기반 날씨 로드 실패:", e);
        setError("위치 기반 날씨 정보를 불러오지 못했어요.");
      } finally {
        setLoading(false);
      }
    };

    const fetchByCity = async (city) => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(
          `http://localhost:8000/api/service/weather/current?city=${encodeURIComponent(
            city
          )}&country=KR`
        );
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        setData(json);
        setSource("fallback");
      } catch (e) {
        console.error("기본 도시 날씨 로드 실패:", e);
        setError("날씨 정보를 불러오지 못했어요.");
      } finally {
        setLoading(false);
      }
    };

    // 1) geolocation 지원 여부 확인
    if (!("geolocation" in navigator)) {
      console.warn("브라우저에서 위치 정보를 지원하지 않습니다.");
      fetchByCity("Seoul");
      return;
    }

    // 2) 현재 위치 요청
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        fetchByCoords(latitude, longitude);
      },
      (err) => {
        console.warn("위치 권한 거부/오류:", err);
        // 권한 거부 등 → Seoul 로 fallback
        fetchByCity("Seoul");
      },
      {
        enableHighAccuracy: false,
        timeout: 8000,
        maximumAge: 5 * 60 * 1000,
      }
    );
  }, []);

  // --------- 스타일 ---------
  const cardStyle = {
    borderRadius: "16px",
    background: "rgba(255, 255, 255, 0.9)",
    boxShadow: "0 4px 12px rgba(0, 0, 0, 0.1)",
    padding: "1rem",
    fontSize: "14px",
    minWidth: "240px",
    border: "1px solid #e5e7eb",
  };

  const headerStyle = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: "0.5rem",
  };

  const titleStyle = { fontWeight: "600", color: "#333" };
  const locationStyle = { fontSize: "12px", color: "#6b7280" };
  const loadingStyle = { fontSize: "12px", color: "#6b7280" };
  const errorStyle = { fontSize: "12px", color: "#ef4444" };
  const tempStyle = { fontSize: "1.5rem", fontWeight: "bold", color: "#333" };
  const descStyle = { marginLeft: "0.5rem", fontSize: "12px", color: "#6b7280" };
  const infoStyle = { fontSize: "12px", color: "#4b5563", marginTop: "0.5rem" };
  const sourceStyle = { fontSize: "11px", color: "#9ca3af", marginTop: "0.25rem" };

  return (
    <div style={cardStyle}>
      <div style={headerStyle}>
        <span style={titleStyle}>오늘 날씨</span>
        <span style={locationStyle}>
          {data?.location ?? (source === "fallback" ? "Seoul, KR" : "위치 확인 중")}
        </span>
      </div>

      {loading && <p style={loadingStyle}>날씨 불러오는 중...</p>}
      {error && <p style={errorStyle}>에러: {error}</p>}

      {!loading && !error && data && (
        <>
          <div>
            <span style={tempStyle}>{Math.round(data.temperature_c)}°C</span>
            <span style={descStyle}>{data.description}</span>
          </div>
          <p style={infoStyle}>
            습도 {data.humidity ?? "-"}% ·{" "}
            {data.is_rainy ? "우산 챙기세요 ☔" : "비 소식 없어요 😊"}
          </p>
          <p style={sourceStyle}>
            {source === "geo"
              ? "현재 위치 기준"
              : "위치 권한 거부/오류로 Seoul 기준"}
          </p>
        </>
      )}
    </div>
  );
}
