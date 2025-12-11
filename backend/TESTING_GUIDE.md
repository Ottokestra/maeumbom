# API Manual Testing Guide

This guide provides `curl` commands to test the newly implemented features: Onboarding Survey, Routine Survey, Menopause Survey, and Weekly Emotion Report.

## 1. Onboarding Survey

**Submit Onboarding Profile (POST /api/onboarding-survey/submit)**
*Note: Requires Auth Token. Replace `YOUR_TOKEN` with a valid JWT.*

```bash
curl -X POST "http://localhost:8000/api/onboarding-survey/submit" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nickname": "TestingUser",
    "age_group": "40대",
    "gender": "여성",
    "marital_status": "기혼",
    "children_yn": "있음",
    "living_with": ["배우자와"],
    "personality_type": "내향적",
    "activity_style": "조용한 활동이 좋아요",
    "stress_relief": ["산책을 해요"],
    "hobbies": ["독서"],
    "atmosphere": []
  }'
```

**Get My Profile (GET /api/onboarding-survey/me)**

```bash
curl -X GET "http://localhost:8000/api/onboarding-survey/me" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Check Status (GET /api/onboarding-survey/status)**

```bash
curl -X GET "http://localhost:8000/api/onboarding-survey/status" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 2. Routine Survey

**Submit Routine Survey Answers (POST /api/routine-survey/submit)**

```bash
curl -X POST "http://localhost:8000/api/routine-survey/submit" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "survey_id": 1,
    "answers": [
      {"question_id": 1, "answer_value": "Y"},
      {"question_id": 2, "answer_value": "N"},
      {"question_id": 3, "answer_value": "Y"}
    ]
  }'
```

## 3. Menopause Survey

**Submit Menopause Survey (POST /api/menopause-survey/submit)**
*Note: MVP does not require auth.*

```bash
curl -X POST "http://localhost:8000/api/menopause-survey/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "FEMALE",
    "answers": [
      {"question_id": 1, "answer_value": 3},
      {"question_id": 2, "answer_value": 0},
      {"question_id": 3, "answer_value": 3}
    ]
  }'
```

**List Questions (GET /api/menopause/questions)**

```bash
curl "http://localhost:8000/api/menopause/questions?gender=FEMALE"
```

## 4. Weekly Emotion Report

**Generate Report (POST /api/v1/reports/emotion/weekly/generate)**

```bash
curl -X POST "http://localhost:8000/api/v1/reports/emotion/weekly/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "weekStart": "2023-11-20"
  }'
```

**Get Report List (GET /api/v1/reports/emotion/weekly/list)**

```bash
curl "http://localhost:8000/api/v1/reports/emotion/weekly/list?userId=1"
```

**Get Report by ID (GET /api/v1/reports/emotion/weekly/{reportId})**

```bash
curl "http://localhost:8000/api/v1/reports/emotion/weekly/1"
```
