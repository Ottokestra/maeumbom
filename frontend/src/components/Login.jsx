// src/components/Login.jsx
import { useState, useEffect } from 'react'
import './Login.css'

const API_BASE_URL = 'http://localhost:8000'

function Login({ onLoginSuccess }) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [config, setConfig] = useState({
    googleClientId: null,
    kakaoClientId: null,
    naverClientId: null
  })

  // 컴포넌트 마운트 시 백엔드에서 Client ID들 가져오기
  useEffect(() => {
    const fetchConfig = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/auth/config`)
        if (response.ok) {
          const data = await response.json()
          setConfig({
            googleClientId: data.google_client_id,
            kakaoClientId: data.kakao_client_id,
            naverClientId: data.naver_client_id
          })
        } else {
          setError('인증 설정을 불러올 수 없습니다. 서버를 확인해주세요.')
        }
      } catch (err) {
        setError('서버 연결 오류: ' + err.message)
      }
    }
    fetchConfig()
  }, [])

  const handleGoogleLogin = async () => {
    setLoading(true)
    setError(null)

    try {
      if (!config.googleClientId) {
        setError('Google 인증 설정을 불러오는 중입니다. 잠시 후 다시 시도해주세요.')
        setLoading(false)
        return
      }

      const redirectUri = `${window.location.origin}/auth/callback`
      const scope = 'openid email profile'
      const responseType = 'code'

      const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
        `client_id=${encodeURIComponent(config.googleClientId)}&` +
        `redirect_uri=${encodeURIComponent(redirectUri)}&` +
        `response_type=${encodeURIComponent(responseType)}&` +
        `scope=${encodeURIComponent(scope)}&` +
        `access_type=offline&` +
        `prompt=select_account`

      window.location.href = authUrl
    } catch (err) {
      setError('로그인 중 오류가 발생했습니다: ' + err.message)
      setLoading(false)
    }
  }

  const handleKakaoLogin = async () => {
    setLoading(true)
    setError(null)

    try {
      if (!config.kakaoClientId) {
        setError('Kakao 인증 설정을 불러오는 중입니다. 잠시 후 다시 시도해주세요.')
        setLoading(false)
        return
      }

      // Kakao 로그인 플래그 설정 (콜백에서 구분하기 위함)
      sessionStorage.setItem('kakao_login', 'true')

      const redirectUri = `${window.location.origin}/auth/callback`
      const responseType = 'code'

      const authUrl = `https://kauth.kakao.com/oauth/authorize?` +
        `client_id=${encodeURIComponent(config.kakaoClientId)}&` +
        `redirect_uri=${encodeURIComponent(redirectUri)}&` +
        `response_type=${encodeURIComponent(responseType)}`

      window.location.href = authUrl
    } catch (err) {
      setError('로그인 중 오류가 발생했습니다: ' + err.message)
      setLoading(false)
    }
  }

  const handleNaverLogin = async () => {
    setLoading(true)
    setError(null)

    try {
      if (!config.naverClientId) {
        setError('Naver 인증 설정을 불러오는 중입니다. 잠시 후 다시 시도해주세요.')
        setLoading(false)
        return
      }

      const redirectUri = `${window.location.origin}/auth/callback`
      const state = Math.random().toString(36).substring(2, 15)
      sessionStorage.setItem('naver_state', state)

      const authUrl = `https://nid.naver.com/oauth2.0/authorize?` +
        `client_id=${encodeURIComponent(config.naverClientId)}&` +
        `redirect_uri=${encodeURIComponent(redirectUri)}&` +
        `response_type=code&` +
        `state=${encodeURIComponent(state)}`

      window.location.href = authUrl
    } catch (err) {
      setError('로그인 중 오류가 발생했습니다: ' + err.message)
      setLoading(false)
    }
  }

  // OAuth callback 이후에는 App.jsx 쪽에서 실제 토큰 처리 & onLoginSuccess 호출

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h1>💜 마음봄</h1>
          <p>감정 분석 AI 서비스</p>
        </div>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        <div className="login-content">
          <p className="login-description">
            소셜 계정으로 로그인하여<br />
            감정 분석 서비스를 이용하세요
          </p>

          <div className="login-buttons-container">
            <button
              className="google-login-button"
              onClick={handleGoogleLogin}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="spinner"></span>
                  로그인 중...
                </>
              ) : (
                <>
                  <svg className="google-icon" viewBox="0 0 24 24">
                    <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                    <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                    <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                    <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                  </svg>
                  Google
                </>
              )}
            </button>

            <button
              className="kakao-login-button"
              onClick={handleKakaoLogin}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="spinner"></span>
                  로그인 중...
                </>
              ) : (
                <>
                  <svg className="kakao-icon" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 3C6.48 3 2 6.58 2 11c0 2.89 1.86 5.44 4.64 7.05-.2.73-.75 2.67-.86 3.1-.13.5.18.49.38.36.15-.1 2.42-1.63 3.36-2.26.78.11 1.58.17 2.39.17 5.52 0 10-3.58 10-8S17.52 3 12 3z" />
                  </svg>
                  Kakao
                </>
              )}
            </button>

            <button
              className="naver-login-button"
              onClick={handleNaverLogin}
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="spinner"></span>
                  로그인 중...
                </>
              ) : (
                <>
                  <span className="naver-icon">N</span>
                  Naver
                </>
              )}
            </button>
          </div>

          <div className="login-footer">
            <p className="privacy-note">
              로그인 시 소셜 계정 정보가 서버에 저장됩니다.<br />
              개인정보 보호 정책에 동의하는 것으로 간주됩니다.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Login
