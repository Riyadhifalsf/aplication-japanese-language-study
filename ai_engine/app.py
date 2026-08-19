from math import exp
from typing import List
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="Japanese Study Intelligence", version="0.1.0")

class StudentSignals(BaseModel):
    accuracy: float = Field(0.0, ge=0, le=1)
    streak_days: int = Field(0, ge=0)
    review_due: int = Field(0, ge=0)
    study_minutes_7d: float = Field(0, ge=0)
    mastered_kanji: int = Field(0, ge=0)
    failed_quizzes_7d: int = Field(0, ge=0)

class Recommendation(BaseModel):
    forgetting_risk: float
    next_action: str
    reason: List[str]

def sigmoid(x: float) -> float:
    return 1.0 / (1.0 + exp(-x))

def score(signals: StudentSignals) -> Recommendation:
    risk = sigmoid(
        1.4 * (1 - signals.accuracy)
        + 0.035 * signals.review_due
        + 0.08 * signals.failed_quizzes_7d
        - 0.018 * signals.streak_days
        - 0.006 * signals.study_minutes_7d
    )
    if signals.review_due >= 8:
        action = "review"
    elif signals.accuracy < 0.70:
        action = "practice_weak_topics"
    elif signals.study_minutes_7d < 60:
        action = "continue_path"
    else:
        action = "advance"
    reasons = []
    if signals.review_due >= 8:
        reasons.append("Banyak item review sudah jatuh tempo.")
    if signals.accuracy < 0.70:
        reasons.append("Akurasi kuis masih di bawah 70%.")
    if signals.study_minutes_7d < 60:
        reasons.append("Waktu belajar 7 hari terakhir masih rendah.")
    if not reasons:
        reasons.append("Progress stabil; lanjutkan path dan pertahankan review.")
    return Recommendation(forgetting_risk=round(risk, 4), next_action=action, reason=reasons)

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/recommend", response_model=Recommendation)
def recommend(signals: StudentSignals):
    return score(signals)
