import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import content, sync, corrections, ai

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Pre-warm AI models at server startup so first request is fast.
    Models load in background threads — server accepts requests immediately.
    """
    logger.info("PALASH Setu backend starting…")
    logger.info(
        "AI models will lazy-load on first request. "
        "To pre-warm, call GET /ai/status after startup."
    )
    yield
    logger.info("PALASH Setu backend shutting down.")


app = FastAPI(
    title="PALASH Setu Backend Server",
    description=(
        "Real-time Hindi→Santali (Ol Chiki) AI translation server for "
        "Jharkhand MTB-MLE primary schools. Powered by IndicTrans2 (MT) "
        "and Whisper Tiny (ASR). Content sync, NIPUN Bharat curriculum API, "
        "and community correction corpus collection."
    ),
    version="2.0.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter app and cross-origin clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(content.router)
app.include_router(sync.router)
app.include_router(corrections.router)
app.include_router(ai.router)           # ← IndicTrans2 + Whisper endpoints


@app.get("/")
def root():
    return {
        "app": "PALASH Setu Backend API v2.0",
        "status": "online",
        "docs": "/docs",
        "aiEndpoints": {
            "status": "/ai/status",
            "translate": "POST /ai/translate",
            "asr": "POST /ai/asr",
            "pipeline": "POST /ai/pipeline",
        },
        "models": {
            "asr": "Whisper Tiny (faster-whisper / CTranslate2, INT8)",
            "mt": "IndicTrans2 indic-indic-1B (AI4Bharat / HuggingFace)",
        },
        "targetVernacular": "Santali (Ol Chiki — sat_Olck)",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
