import os
import numpy as np
import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

# --- 1. 경로 설정 및 파일 로드 ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(BASE_DIR, 'diabetes_model.pkl')
scaler_path = os.path.join(BASE_DIR, 'scaler.pkl')

try:
    model = joblib.load(model_path)
    scaler = joblib.load(scaler_path)
    print("✅ 성공: 모델과 스케일러가 정상적으로 로드되었습니다.")
except Exception as e:
    print(f"❌ 실패: 로드 중 에러가 발생했습니다 -> {e}")
    # 파일 로드 실패 시 서버가 뜨지 않도록 강제 종료하거나 에러 로그를 남깁니다.

# --- 2. 데이터 구조 정의 (함수 밖으로 이동) ---
class UserData(BaseModel):
    glucose: float
    bmi: float
    age: int
    pedigree_log: float

# --- 3. 예측 엔드포인트 ---
@app.post("/predict")
async def predict(data: UserData):
    try:
        # 1. BMI 기반 파생변수 생성 (허리둘레 미사용 시)
        current_bmi = data.bmi
        risk_factor = (current_bmi ** 1.2) / 10
        abdominal_risk = (data.glucose * risk_factor) / 100

        # 2. 모델 학습 시 순서 그대로 배열 생성
        # [혈당, BMI, 나이, 가족력_로그, 복부위험지수]
        raw_features = np.array([[
            data.glucose, 
            current_bmi, 
            data.age, 
            data.pedigree_log, 
            abdominal_risk
        ]])

        # 3. Scaler 적용 (중요!)
        scaled_features = scaler.transform(raw_features)

        # 4. 결과 예측
        prob = model.predict_proba(scaled_features)[0][1]
        
        return {
            "probability": round(float(prob) * 100, 2),
            "result": "위험" if prob > 0.5 else "정상",
            "message": "성공적으로 분석되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)