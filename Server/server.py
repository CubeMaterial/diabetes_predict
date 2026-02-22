import os
import numpy as np
import pandas as pd
import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

# --- 1. 경로 설정 및 파일 로드 ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(BASE_DIR, 'diabetes_model.h5')
scaler_path = os.path.join(BASE_DIR, 'scaler.h5')

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
    parents: int
    siblings: int
    grandparents:int
    # skin:float

# --- 3. 예측 엔드포인트 ---
@app.post("/predict")
async def predict(data: UserData):
    try:
        glucose = data.glucose
        if glucose == 0:
            glucose = (0.9806825594100111 * data.bmi) + (0.6817116341473727 * data.age) + 65.60660909858092
        
        skin =  (0.7320350425409223 * data.bmi) + (0.07081157992000305 * data.age) +  2.8965508352678846    

        baseScore = 0.078; 

        pScore = 1.0 * np.log10(1 + data.parents)
        sScore = 0.8 * np.log10(1 + data.siblings)
        gScore = 0.5 * np.log10(1 + data.grandparents)

        totalRawScore = baseScore + pScore + sScore + gScore;    
        
        risk_factor = (data.bmi ** 1.2) / 10
        abdominal_risk = (glucose * risk_factor) / 100

        input_df = pd.DataFrame([{
            'BMI': data.bmi,
            '나이': data.age,
            '피부두께': skin,
            '혈당': glucose,
            'Abdominal_Glucose_Risk': abdominal_risk,
            '가족력로그': totalRawScore
        }])

        # 3. Scaler 적용 (중요!)
        scaled_features = scaler.transform(input_df)

        # 4. 결과 예측
        prob = model.predict_proba(scaled_features)[0][1]

        prob_percent = round(float(prob) * 100, 2)
    
    # 구간 나누기 로직
        if prob_percent >= 60:
            result = "위험"
            message = "당뇨 위험도가 매우 높습니다. 병원 방문을 권장합니다."
        elif prob_percent >= 35:
            result = "주의"
            message = "당뇨 전단계 상태일 가능성이 높습니다. 식단과 운동이 필요합니다."
        else:
            result = "정상"
            message = "수치가 안정적입니다. 정기적인 체크를 잊지 마세요."
        
        return {
            "probability": round(float(prob) * 100, 2),
            "result": result,
            "message": message
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="192.168.0.17", port=8000)