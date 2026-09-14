from fastapi import APIRouter, Query
from typing import Optional, List

router = APIRouter(tags=["Content"])

SAMPLE_LESSONS = [
    {
        "id": "les_1",
        "grade": 1,
        "subject": "language",
        "type": "lesson_script",
        "hindiText": "बच्चों, आपका पाठशाला में स्वागत है!",
        "santaliText": "ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱟᱯᱮᱭᱟᱜ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱨᱮ ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ!",
        "phoneticGuide": "Gidra ko, apeyag itun asra re sagun daram!",
        "santaliAudioRef": "greetings_johar.wav",
        "confidence": "high",
        "outcomeIds": ["NIPUN_L1_01"]
    },
    {
        "id": "les_2",
        "grade": 1,
        "subject": "math",
        "type": "activity",
        "hindiText": "आओ एक, दो, तीन गिनती सीखें।",
        "santaliText": "ᱦᱤᱡᱩᱜ ᱯᱮ ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱪᱮᱫᱚᱜᱼᱟ।",
        "phoneticGuide": "Hijug pe mit, bar, pe lekha bon chedog-a.",
        "santaliAudioRef": "lesson_2_math.wav",
        "confidence": "high",
        "outcomeIds": ["NIPUN_M1_01"]
    }
]

SAMPLE_VOCAB = [
    {
        "id": "voc_1",
        "hindiWord": "नमस्ते / जोहार",
        "santaliWord": "ᱡᱚᱦᱟᱨ",
        "phoneticGuide": "Johar",
        "category": "greetings",
        "santaliAudioRef": "greetings_johar.wav",
        "confidence": "high"
    },
    {
        "id": "voc_2",
        "hindiWord": "एक (1)",
        "santaliWord": "ᱢᱤᱫ",
        "phoneticGuide": "Mit",
        "category": "numbers",
        "santaliAudioRef": "numbers_mit.wav",
        "confidence": "high"
    }
]

@router.get("/lessons")
def get_lessons(grade: Optional[int] = None, subject: Optional[str] = None):
    res = SAMPLE_LESSONS
    if grade:
        res = [l for l in res if l["grade"] == grade]
    if subject:
        res = [l for l in res if l["subject"] == subject]
    return res

@router.get("/lessons/{lesson_id}")
def get_lesson_detail(lesson_id: str):
    for l in SAMPLE_LESSONS:
        if l["id"] == lesson_id:
            return l
    return {"error": "Lesson not found"}

@router.get("/vocabulary")
def get_vocabulary(category: Optional[str] = None):
    if category:
        return [v for v in SAMPLE_VOCAB if v["category"] == category]
    return SAMPLE_VOCAB

@router.get("/outcomes")
def get_outcomes():
    return [
        {"id": "NIPUN_L1_01", "code": "L1.1", "description": "Listens and responds in Santali mother tongue."},
        {"id": "NIPUN_M1_01", "code": "M1.1", "description": "Counts objects 1 to 10 in Santali."}
    ]
