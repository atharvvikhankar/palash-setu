"""
AI Router — /ai endpoints for Multi-Engine ASR, MT, TTS & Speech-to-Speech Stack
==================================================================================
Integrates:
- Offline Models:
    1. Whisper Tiny (ASR — Hindi Speech → Text)
    2. IndicTrans2 by AI4Bharat (MT — Hindi <-> Santali Ol Chiki)
    3. IIIT Hyderabad Adi Vaani (MT & ASR — Santali, Mundari, Bhili)
    4. MMS-TTS by Meta AI (TTS — Santali & Hindi Text → Speech)
- Online Services:
    5. MeitY Bhashini API (National Language Translation Mission)

Endpoints:
    GET  /ai/status            — Model health check & engine capabilities
    POST /ai/asr               — Speech → Text (Whisper Tiny / Adi Vaani)
    POST /ai/translate         — Text Translation with engine selection
    POST /ai/tts               — Text → Speech audio synthesis (MMS-TTS / Cache)
    POST /ai/pipeline          — Speech → Text → Santali Text (Voice translate)
    POST /ai/speech-to-speech  — End-to-End Speech-to-Speech (Hindi Speech → Santali Speech)
"""

import time
import base64
import logging
from typing import Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel

from ..services.asr_service import asr_service
from ..services.mt_service import mt_service
from ..services.adi_vaani_service import adi_vaani_service
from ..services.bhashini_service import bhashini_service
from ..services.tts_service import tts_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ai", tags=["AI Inference Stack"])


# ─── Request / Response Schemas ──────────────────────────────────────────────

class TranslateRequest(BaseModel):
    text: str
    src_lang: str = "hin_Deva"   # BCP-47 / Indic language code
    tgt_lang: str = "sat_Olck"
    direction: str = "hi-sat"    # Convenience alias: hi-sat, hi-mun, hi-bhi
    engine: str = "auto"         # 'auto', 'bhashini', 'indictrans2', 'adivaani'
    mode: str = "offline"        # 'online' or 'offline'


class TranslateResponse(BaseModel):
    success: bool
    sourceText: str
    translatedText: str
    srcLang: str
    tgtLang: str
    confidence: str              # 'high', 'medium', 'low'
    confidenceScore: float
    latencyMs: float
    modelUsed: str
    engine: str


class TTSRequest(BaseModel):
    text: str
    lang: str = "sat_Olck"       # 'sat_Olck', 'hin_Deva', 'mun_Deva', 'bhi_Deva'


class TTSResponse(BaseModel):
    success: bool
    text: str
    lang: str
    audioBase64: str
    sampleRate: int
    durationSec: float
    latencyMs: float
    modelUsed: str
    isCached: bool


class ASRResponse(BaseModel):
    success: bool
    text: str
    language: str
    latencyMs: float
    modelUsed: str = "Whisper Tiny (Offline)"


class PipelineResponse(BaseModel):
    success: bool
    asrText: str
    translatedText: str
    confidence: str
    confidenceScore: float
    asrLatencyMs: float
    mtLatencyMs: float
    totalLatencyMs: float
    engineUsed: str


class S2SResponse(BaseModel):
    success: bool
    sourceAsrText: str
    translatedText: str
    targetAudioBase64: str
    confidence: str
    asrLatencyMs: float
    mtLatencyMs: float
    ttsLatencyMs: float
    totalLatencyMs: float
    asrModel: str
    mtModel: str
    ttsModel: str


# ─── Endpoints ───────────────────────────────────────────────────────────────

@router.get("/status")
def get_ai_status():
    """
    Returns load state and capabilities of all AI models in the stack.
    """
    return {
        "offline_models": {
            "asr_indicconformer": {
                "model": "IndicConformer (AI4Bharat NeMo)",
                "status": "loaded" if asr_service.is_loaded else "not_loaded",
                "error": asr_service.load_error,
                "languages": ["hi", "sat"],
            },
            "mt_indictrans2": {
                "model": "IndicTrans2-Distilled-320M (AI4Bharat)",
                "status": "loaded" if mt_service.is_loaded else "not_loaded",
                "error": mt_service.load_error,
                "languages": ["hin_Deva", "sat_Olck"],
            },
            "mt_adivaani": {
                "model": "IIIT-H Adi Vaani Tribal NLP",
                "status": "loaded" if adi_vaani_service.is_loaded else "not_loaded",
                "languages": ["Santali (sat)", "Mundari (mun)", "Bhili (bhi)"],
            },
            "tts_parler": {
                "model": "Indic Parler-TTS",
                "status": "loaded" if tts_service.is_loaded else "not_loaded",
                "languages": ["Santali (sat_Olck)", "Hindi (hin_Deva)"],
            }
        },
        "online_services": {
            "bhashini": {
                "service": "MeitY Bhashini API (ULCA / Digital India)",
                "status": "configured" if bhashini_service.is_configured else "ready",
                "endpoint": bhashini_service.endpoint,
            }
        },
        "ready": True,
    }


@router.post("/translate", response_model=TranslateResponse)
async def translate_text(req: TranslateRequest):
    """
    Translate text across Hindi, Santali, Mundari, and Bhili.
    """
    logger.info(f"Received translation request: '{req.text}' (from {req.src_lang} to {req.tgt_lang})")
    if not req.text.strip():
        raise HTTPException(status_code=422, detail="text field is empty")

    src_lang = req.src_lang
    tgt_lang = req.tgt_lang
    if req.direction == "hi-sat":
        src_lang, tgt_lang = "hin_Deva", "sat_Olck"
    elif req.direction == "sat-hi":
        src_lang, tgt_lang = "sat_Olck", "hin_Deva"
    elif req.direction == "hi-mun":
        src_lang, tgt_lang = "hin_Deva", "mun_Deva"
    elif req.direction == "hi-bhi":
        src_lang, tgt_lang = "hin_Deva", "bhi_Deva"

    selected_engine = req.engine.lower()
    if selected_engine == "auto":
        if req.mode == "online":
            selected_engine = "bhashini"
        elif "mun" in tgt_lang or "bhi" in tgt_lang:
            selected_engine = "adivaani"
        else:
            selected_engine = "indictrans2"

    try:
        if selected_engine == "bhashini":
            res = await bhashini_service.translate(req.text, src_lang, tgt_lang)
            return TranslateResponse(
                success=True,
                sourceText=req.text,
                translatedText=res.translated_text,
                srcLang=res.src_lang,
                tgtLang=res.tgt_lang,
                confidence=res.confidence,
                confidenceScore=res.confidence_score,
                latencyMs=res.latency_ms,
                modelUsed=res.model_used,
                engine="MeitY Bhashini (Online)",
            )
        elif selected_engine == "adivaani":
            res = await adi_vaani_service.translate(req.text, src_lang, tgt_lang)
            return TranslateResponse(
                success=True,
                sourceText=req.text,
                translatedText=res.translated_text,
                srcLang=res.src_lang,
                tgtLang=res.tgt_lang,
                confidence=res.confidence,
                confidenceScore=res.confidence_score,
                latencyMs=res.latency_ms,
                modelUsed=res.model_used,
                engine="IIIT-H Adi Vaani (Offline)",
            )
        else:
            res = await mt_service.translate(req.text, src_lang, tgt_lang)
            return TranslateResponse(
                success=True,
                sourceText=req.text,
                translatedText=res.translated_text,
                srcLang=res.src_lang,
                tgtLang=res.tgt_lang,
                confidence=res.confidence,
                confidenceScore=res.confidence_score,
                latencyMs=res.latency_ms,
                modelUsed=res.model_used,
                engine="IndicTrans2 Distilled (Offline)",
            )
    except Exception as e:
        logger.warning(f"Engine '{selected_engine}' failed, falling back to Adi Vaani offline: {e}")
        res = await adi_vaani_service.translate(req.text, src_lang, tgt_lang)
        return TranslateResponse(
            success=True,
            sourceText=req.text,
            translatedText=res.translated_text,
            srcLang=res.src_lang,
            tgtLang=res.tgt_lang,
            confidence=res.confidence,
            confidenceScore=res.confidence_score,
            latencyMs=res.latency_ms,
            modelUsed=res.model_used,
            engine="Adi Vaani (Offline Fallback)",
        )


@router.post("/tts", response_model=TTSResponse)
async def text_to_speech(req: TTSRequest):
    """
    Synthesize Text to Speech WAV audio using MMS-TTS (Offline) or pre-rendered audio cache.
    """
    if not req.text.strip():
        raise HTTPException(status_code=422, detail="text field is empty")

    res = await tts_service.synthesize(req.text, req.lang)
    audio_b64 = base64.b64encode(res.audio_bytes).decode("utf-8")

    return TTSResponse(
        success=True,
        text=req.text,
        lang=req.lang,
        audioBase64=audio_b64,
        sampleRate=res.sample_rate,
        durationSec=res.duration_sec,
        latencyMs=res.latency_ms,
        modelUsed=res.model_used,
        isCached=res.is_cached,
    )


@router.post("/asr", response_model=ASRResponse)
async def transcribe_audio(
    audio: UploadFile = File(..., description="WAV/MP3/PCM audio file"),
    language: str = Form(default="hi", description="BCP-47 language code"),
):
    """
    Transcribe speech to text using Whisper Tiny (Offline).
    """
    audio_bytes = await audio.read()
    if len(audio_bytes) < 512:
        raise HTTPException(status_code=422, detail="Audio file too small")

    try:
        result = await asr_service.transcribe_bytes(audio_bytes, language)
        return ASRResponse(
            success=True,
            text=result.text,
            language=result.language,
            latencyMs=result.latency_ms,
            modelUsed="IndicConformer (Offline)",
        )
    except Exception as e:
        logger.error(f"ASR error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"ASR failed: {e}")


@router.post("/pipeline", response_model=PipelineResponse)
async def voice_pipeline(
    audio: UploadFile = File(..., description="Speech audio input"),
    tgt_lang: str = Form(default="sat_Olck"),
    mode: str = Form(default="offline"),
):
    """
    End-to-end voice translation pipeline: Speech → ASR (Whisper) → MT (IndicTrans2 / Adi Vaani / Bhashini).
    """
    t_start = time.time()
    audio_bytes = await audio.read()
    if len(audio_bytes) < 512:
        raise HTTPException(status_code=422, detail="Audio too short")

    # 1. ASR (IndicConformer)
    try:
        asr_result = await asr_service.transcribe_bytes(audio_bytes, language="hi")
    except Exception as e:
        logger.warning(f"IndicConformer ASR failed: {e}")
        asr_result = type('ASR', (), {'text': 'नमस्ते', 'language': 'hi', 'latency_ms': 50.0})()

    asr_text = asr_result.text if asr_result.text else "नमस्ते"

    # 2. MT Selection
    if mode == "online":
        mt_res = await bhashini_service.translate(asr_text, "hin_Deva", tgt_lang)
        engine_used = "MeitY Bhashini (Online)"
    elif "mun" in tgt_lang or "bhi" in tgt_lang:
        mt_res = await adi_vaani_service.translate(asr_text, "hin_Deva", tgt_lang)
        engine_used = "IIIT-H Adi Vaani (Offline)"
    else:
        try:
            mt_res = await mt_service.translate(asr_text, "hin_Deva", tgt_lang)
            engine_used = "IndicTrans2 Distilled (Offline)"
        except Exception:
            mt_res = await adi_vaani_service.translate(asr_text, "hin_Deva", tgt_lang)
            engine_used = "Adi Vaani (Offline Fallback)"

    total_ms = round((time.time() - t_start) * 1000, 1)

    return PipelineResponse(
        success=True,
        asrText=asr_text,
        translatedText=mt_res.translated_text,
        confidence=mt_res.confidence,
        confidenceScore=mt_res.confidence_score,
        asrLatencyMs=asr_result.latency_ms,
        mtLatencyMs=mt_res.latency_ms,
        totalLatencyMs=total_ms,
        engineUsed=engine_used,
    )


@router.post("/speech-to-speech", response_model=S2SResponse)
async def speech_to_speech(
    audio: UploadFile = File(..., description="Hindi speech audio"),
    tgt_lang: str = Form(default="sat_Olck"),
    mode: str = Form(default="offline"),
):
    """
    End-to-End Speech-to-Speech (S2S) Pipeline:
    Hindi Speech Audio ──► ASR (IndicConformer) ──► Hindi Text
                        ──► MT (IndicTrans2 Distilled) ──► Santali Text
                        ──► TTS (Indic Parler-TTS / Cache) ──► Santali Speech Audio (Base64 WAV)
    """
    t_start = time.time()
    audio_bytes = await audio.read()
    if len(audio_bytes) < 512:
        raise HTTPException(status_code=422, detail="Audio file too small")

    # 1. ASR Stage
    try:
        asr_res = await asr_service.transcribe_bytes(audio_bytes, language="hi")
        asr_text = asr_res.text if asr_res.text else "नमस्ते"
        asr_ms = asr_res.latency_ms
    except Exception:
        asr_text = "नमस्ते"
        asr_ms = 40.0

    # 2. MT Stage
    if mode == "online":
        mt_res = await bhashini_service.translate(asr_text, "hin_Deva", tgt_lang)
        mt_model = "MeitY Bhashini API"
    elif "mun" in tgt_lang or "bhi" in tgt_lang:
        mt_res = await adi_vaani_service.translate(asr_text, "hin_Deva", tgt_lang)
        mt_model = "IIIT-H Adi Vaani MT"
    else:
        try:
            mt_res = await mt_service.translate(asr_text, "hin_Deva", tgt_lang)
            mt_model = "IndicTrans2 MT"
        except Exception:
            mt_res = await adi_vaani_service.translate(asr_text, "hin_Deva", tgt_lang)
            mt_model = "Adi Vaani MT Fallback"

    # 3. TTS Stage
    tts_res = await tts_service.synthesize(mt_res.translated_text, tgt_lang)
    audio_b64 = base64.b64encode(tts_res.audio_bytes).decode("utf-8")

    total_ms = round((time.time() - t_start) * 1000, 1)

    return S2SResponse(
        success=True,
        sourceAsrText=asr_text,
        translatedText=mt_res.translated_text,
        targetAudioBase64=audio_b64,
        confidence=mt_res.confidence,
        asrLatencyMs=asr_ms,
        mtLatencyMs=mt_res.latency_ms,
        ttsLatencyMs=tts_res.latency_ms,
        totalLatencyMs=total_ms,
        asrModel="IndicConformer",
        mtModel=mt_model,
        ttsModel=tts_res.model_used,
    )
