# 벡터 스토어 재초기화 가이드

`sample_emotions.json`을 17개 감정으로 변경한 후, 벡터 스토어를 재초기화해야 RAG 모델이 새로운 데이터를 사용할 수 있습니다.

## 방법 1: Python 스크립트 실행 (권장)

가장 간단한 방법입니다.

```bash
cd backend/engine/emotion-analysis
python reinit_vectorstore.py
```

스크립트가 자동으로:
1. 현재 벡터 스토어 상태 확인
2. 기존 데이터 삭제
3. 새로운 17개 감정 데이터로 재초기화
4. 결과 출력

## 방법 2: API 엔드포인트 호출

서버가 실행 중일 때 사용할 수 있습니다.

### curl 사용
```bash
curl -X POST http://localhost:8000/api/init
```

### Python requests 사용
```python
import requests

response = requests.post("http://localhost:8000/api/init")
print(response.json())
```

### 브라우저에서
1. 서버 실행: `http://localhost:8000/docs`
2. `/api/init` POST 엔드포인트 찾기
3. "Try it out" 클릭
4. "Execute" 클릭

## 재초기화 확인

재초기화 후 다음을 확인하세요:

1. **벡터 스토어 문서 수**: 491개 (sample_emotions.json의 항목 수)
2. **감정 분포**: 17개 감정이 모두 포함되어야 함
   - joy, excitement, confidence, love, relief, enlightenment, interest
   - discontent, shame, sadness, guilt, depression, boredom, contempt, anger, fear, confusion

## 주의사항

- 재초기화하면 기존 벡터 스토어의 모든 데이터가 삭제되고 새로 생성됩니다
- 재초기화는 몇 초에서 수십 초가 걸릴 수 있습니다 (데이터 양에 따라)
- 재초기화 중에는 API 요청이 느려질 수 있습니다

## 문제 해결

### 벡터 스토어가 비어있음
- `sample_emotions.json` 파일 경로 확인
- `data_loader.py`가 올바른 감정 코드를 사용하는지 확인

### 감정 분포가 이상함
- `sample_emotions.json`의 `emotion` 필드가 17개 감정 코드인지 확인
- `convert_emotions.py` 스크립트로 변환이 제대로 되었는지 확인

