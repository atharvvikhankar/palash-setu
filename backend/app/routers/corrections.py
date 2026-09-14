import json
import os
import logging
from typing import List
from fastapi import APIRouter
from pydantic import BaseModel
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Community Corrections"])


class CorrectionRequest(BaseModel):
    sourceText: str
    originalOutput: str
    correctedOutput: str
    correctorType: str  # 'teacher' or 'native_speaker'
    language: str       # e.g., 'Santali', 'Mundari', 'Ho'

class SyncRequest(BaseModel):
    corrections: List[CorrectionRequest]

CORPUS_FILE = "community_corpus.json"

def _append_to_corpus(correction: dict):
    corpus = []
    if os.path.exists(CORPUS_FILE):
        try:
            with open(CORPUS_FILE, "r", encoding="utf-8") as f:
                corpus = json.load(f)
        except json.JSONDecodeError:
            pass
            
    correction["verification_status"] = "UNVERIFIED"
    correction["timestamp"] = datetime.now(timezone.utc).isoformat()
    corpus.append(correction)
    
    with open(CORPUS_FILE, "w", encoding="utf-8") as f:
        json.dump(corpus, f, ensure_ascii=False, indent=2)


@router.post("/corrections", status_code=201)
def submit_correction(req: CorrectionRequest):
    """Store community correction for future dataset retraining."""
    logger.info(
        f"Correction received: '{req.sourceText}' → '{req.correctedOutput}' "
        f"by {req.correctorType} for {req.language}"
    )
    _append_to_corpus(req.model_dump())
    
    return {
        "success": True,
        "receivedAt": datetime.now(timezone.utc).isoformat(),
        "message": "Correction stored in community corpus pipeline.",
    }

@router.post("/corrections/sync", status_code=200)
def sync_corrections(req: SyncRequest):
    """Batch sync unsynced corrections from devices."""
    count = 0
    for corr in req.corrections:
        _append_to_corpus(corr.model_dump())
        count += 1
        
    logger.info(f"Batch synced {count} corrections to corpus.")
    return {
        "success": True,
        "syncedCount": count,
        "message": "Batch corrections synced to community corpus.",
    }
