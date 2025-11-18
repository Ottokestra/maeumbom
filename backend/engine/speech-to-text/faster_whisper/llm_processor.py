"""
마음봄 - LLM 후처리 엔진
Ollama 또는 OpenAI를 사용한 텍스트 후처리
"""

import os
import requests
import json
from typing import Optional
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()


class LLMProcessor:
    """Ollama 또는 OpenAI LLM을 사용한 텍스트 후처리"""
    
    def __init__(
        self,
        provider: str = "ollama",
        model: str = "llama3.2:latest",
        temperature: float = 0.7,
        max_tokens: int = 500,
        system_prompt: str = "",
        base_url: str = None,
        api_key: str = None
    ):
        """
        Args:
            provider: "ollama" 또는 "openai"
            model: 사용할 모델명
            temperature: 생성 온도
            max_tokens: 최대 토큰 수
            system_prompt: 시스템 프롬프트
            base_url: API 베이스 URL (Ollama 전용)
            api_key: API 키 (OpenAI: 환경변수에서 자동 로드, Ollama: "ollama")
        """
        self.provider = provider.lower()
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.system_prompt = system_prompt
        
        # 프로바이더별 설정
        if self.provider == "openai":
            self.api_key = os.getenv("OPENAI_API_KEY", api_key)
            self.base_url = "https://api.openai.com/v1"
            self.chat_url = f"{self.base_url}/chat/completions"
            print(f"🔗 OpenAI API 연결")
            print(f"🤖 모델: {self.model}")
            
            if not self.api_key or self.api_key == "your-openai-api-key-here":
                print("⚠️  경고: OpenAI API 키가 설정되지 않았습니다.")
                print("💡 .env 파일에 OPENAI_API_KEY를 설정하세요.")
            else:
                print("✅ OpenAI API 키 로드 완료")
                
        elif self.provider == "ollama":
            self.base_url = base_url or "http://localhost:11434/v1"
            self.base_url = self.base_url.rstrip('/')
            self.api_key = api_key or "ollama"
            self.chat_url = f"{self.base_url}/chat/completions"
            print(f"🔗 Ollama 연결: {self.base_url}")
            print(f"🤖 모델: {self.model}")
            # 연결 테스트
            self._test_ollama_connection()
        else:
            raise ValueError(f"지원하지 않는 프로바이더: {provider}. 'ollama' 또는 'openai'를 사용하세요.")
        
    def _test_ollama_connection(self):
        """Ollama 연결 테스트"""
        try:
            # 간단한 테스트 요청
            response = requests.post(
                self.chat_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": [
                        {"role": "user", "content": "안녕"}
                    ],
                    "max_tokens": 50,
                    "temperature": 0.1
                },
                timeout=60
            )
            if response.status_code == 200:
                print("✅ Ollama 연결 성공")
            else:
                print(f"⚠️  Ollama 응답 코드: {response.status_code}")
                print(f"   {response.text}")
                
        except requests.exceptions.ConnectionError:
            print("⚠️  Ollama 서버에 연결할 수 없습니다.")
            print("💡 Ollama가 실행 중인지 확인하세요: ollama serve")
        except Exception as e:
            print(f"⚠️  Ollama 연결 테스트 실패: {e}")
            
    
    def chat(self, user_input: str) -> str:
        """
        사용자 입력에 대해 자연스럽게 대화로 응답
        """
        if not user_input or user_input.strip() == "":
            return ""

        try:
            # 1. 메시지 구성 (한국어 고정)
            # 토큰 제한 지침
            token_instruction = f"답변은 반드시 {self.max_tokens}토큰(약 150자) 이내로 간결하게 작성해. 2-3문장으로 핵심만 전달해."
            
            # config.yaml의 system_prompt + 언어 지침 + 토큰 제한
            system_content = self.system_prompt
            if system_content:
                system_content += f"\n\n항상 한국어만 사용하고, 한자·영어·일본어를 섞지 마.\n\n{token_instruction}"
            else:
                # system_prompt가 비어있으면 기본값
                system_content = (
                    "너는 사용자에게 도움이 되는 친절한 AI 친구이고 이름은 '봄'이야. "
                    "자연스럽게 대답해줘. "
                    f"\n\n항상 한국어만 사용하고, 한자·영어·일본어를 섞지 마.\n\n{token_instruction}"
                )
            
            messages = [
                {
                    "role": "system",
                    "content": system_content
                },
                {
                    "role": "user",
                    "content": user_input
                }
            ]
            
            print(f"[디버그] 프로바이더: {self.provider}")
            print(f"[디버그] 시스템 프롬프트:\n{system_content}\n")

            # 3. API 요청
            response = requests.post(
                self.chat_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": messages,
                    "temperature": self.temperature,
                    "max_tokens": self.max_tokens
                },
                timeout=60
            )
            
            # 4. 응답 파싱
            if response.status_code == 200:
                result = response.json()
                print(f"[디버그] {self.provider.upper()} 응답: {result}")
                
                # 모델의 답변 텍스트 추출
                message = result["choices"][0]["message"]
                bot_reply = message.get("content", "").strip()
                
                # Ollama의 일부 모델 (예: gpt-oss)은 content가 비어있고 reasoning에 실제 답변이 있음
                if not bot_reply and "reasoning" in message:
                    bot_reply = message["reasoning"].strip()
                
                print(f"[디버그] 원본 LLM 답변: '{bot_reply}'")
                return bot_reply
            else:
                print(f"❌ API 오류: {response.status_code} - {response.text}")
                if self.provider == "openai":
                    return "죄송해요, OpenAI API 호출에 실패했습니다."
                else:
                    return "죄송해요, 지금은 대답하기 어려워요."

        except Exception as e:
            print(f"❌ Chat 오류: {e}")
            import traceback
            traceback.print_exc()
            return "오류가 발생했습니다."
            
    def enhance_emotion(self, text: str) -> dict:
        """
        감정 분석 및 공감 응답 생성 (향후 확장용)
        
        Args:
            text: 사용자 발화 텍스트
            
        Returns:
            {emotion, empathy_response}
        """
        try:
            user_prompt = f"""
다음 문장의 감정을 분석하고 공감하는 한 줄 응답을 생성하세요.

문장: {text}

JSON 형식으로 답하세요:
{{"emotion": "감정", "response": "공감 응답"}}
"""
            
            response = requests.post(
                self.chat_url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": [
                        {"role": "user", "content": user_prompt}
                    ],
                    "temperature": 0.7,
                    "max_tokens": 500
                },
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                content = result["choices"][0]["message"]["content"].strip()
                
                # JSON 파싱 시도
                try:
                    return json.loads(content)
                except:
                    return {
                        "emotion": "알 수 없음",
                        "response": content
                    }
                    
            else:
                return {
                    "emotion": "알 수 없음",
                    "response": ""
                }
                
        except Exception as e:
            print(f"⚠️  감정 분석 오류: {e}")
            return {
                "emotion": "알 수 없음",
                "response": ""
            }

