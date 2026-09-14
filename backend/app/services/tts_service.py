"""
TTS Service — Indic Parler-TTS
==============================
Uses Indic Parler-TTS for Santali and Hindi, alongside
pre-synthesized audio caching for low-RAM mobile/tablet devices.

Model: ai4bharat/indic-parler-tts
"""

import os
import io
import time
import logging
import asyncio
from dataclasses import dataclass
from typing import Optional
from pathlib import Path

logger = logging.getLogger(__name__)

# Pre-recorded audio directory
AUDIO_CACHE_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
MODELS_DIR = Path(__file__).parent.parent.parent / "models"


@dataclass
class TTSResult:
    audio_bytes: bytes
    sample_rate: int
    duration_sec: float
    latency_ms: float
    model_used: str
    is_cached: bool


class TTSService:
    """
    Offline TTS Engine for Santali and Hindi using Indic Parler-TTS.
    """

    def __init__(self):
        self._model = None
        self._tokenizer = None
        self._load_error: Optional[str] = None
        self._model_loaded = False
        self._lock = asyncio.Lock()

    def _load_model(self):
        if self._model_loaded:
            return
            
        try:
            from parler_tts import ParlerTTSForConditionalGeneration
            from transformers import AutoTokenizer
            
            logger.info("Loading Indic Parler-TTS model…")
            t0 = time.time()
            
            cache_dir = str(MODELS_DIR / "parler_tts")
            
            self._tokenizer = AutoTokenizer.from_pretrained(
                "ai4bharat/indic-parler-tts", 
                cache_dir=cache_dir
            )
            self._model = ParlerTTSForConditionalGeneration.from_pretrained(
                "ai4bharat/indic-parler-tts", 
                cache_dir=cache_dir,
                low_cpu_mem_usage=True
            )
            
            elapsed = round((time.time() - t0) * 1000)
            logger.info(f"Indic Parler-TTS loaded in {elapsed}ms")
            self._model_loaded = True
        except Exception as e:
            self._load_error = str(e)
            logger.error(f"Indic Parler-TTS load failed: {e}")

    @property
    def is_loaded(self) -> bool:
        return self._model_loaded

    @property
    def load_error(self) -> Optional[str]:
        return self._load_error

    async def synthesize(self, text: str, lang: str = "sat_Olck") -> TTSResult:
        """
        Synthesizes text into audio bytes.
        """
        t0 = time.time()
        clean_text = text.strip()

        # 1. Check local pre-recorded audio cache first
        cached_wav = self._get_cached_audio(clean_text)
        if cached_wav:
            latency = round((time.time() - t0) * 1000, 1)
            return TTSResult(
                audio_bytes=cached_wav,
                sample_rate=44100, # default fallback
                duration_sec=1.5,
                latency_ms=latency,
                model_used="Pre-synthesized Audio Cache (Offline)",
                is_cached=True,
            )

        # 2. Dynamic synthesis using Parler-TTS
        async with self._lock:
            if not self._model_loaded:
                loop = asyncio.get_running_loop()
                await loop.run_in_executor(None, self._load_model)
                
        if self._load_error:
            raise RuntimeError(f"TTS model not available: {self._load_error}")

        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(None, self._synthesize_sync, clean_text, lang)
        return result

    def _synthesize_sync(self, text: str, lang: str) -> TTSResult:
        import soundfile as sf
        import torch
        
        t0 = time.time()
        
        # Parler TTS uses a description for voice conditioning
        description = "A clear, natural voice, moderate pace, classroom-appropriate tone."
        
        input_ids = self._tokenizer(description, return_tensors="pt").input_ids
        prompt_ids = self._tokenizer(text, return_tensors="pt").input_ids

        with torch.no_grad():
            generation = self._model.generate(input_ids=input_ids, prompt_input_ids=prompt_ids)
            
        audio_arr = generation.cpu().numpy().squeeze()
        sample_rate = self._model.config.sampling_rate
        
        # Write to bytes buffer
        buf = io.BytesIO()
        sf.write(buf, audio_arr, sample_rate, format='WAV')
        audio_bytes = buf.getvalue()
        
        duration = len(audio_arr) / sample_rate
        latency = round((time.time() - t0) * 1000, 1)

        return TTSResult(
            audio_bytes=audio_bytes,
            sample_rate=sample_rate,
            duration_sec=round(duration, 1),
            latency_ms=latency,
            model_used="Indic Parler-TTS",
            is_cached=False,
        )

    def _get_cached_audio(self, text: str) -> Optional[bytes]:
        """Looks up pre-rendered WAV file in assets/audio/ if text matches lesson phrases."""
        filename_map = {
            "Johar": "lesson_1_intro.wav",
            "ᱡᱚᱦᱟᱨ": "lesson_1_intro.wav",
            "ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟ": "greeting.wav",
            "ᱥᱟᱨᱦᱟᱣ": "thankyou.wav",
        }
        ref = filename_map.get(text)
        if ref and os.path.exists(AUDIO_CACHE_DIR):
            file_path = os.path.join(AUDIO_CACHE_DIR, ref)
            if os.path.isfile(file_path):
                with open(file_path, "rb") as f:
                    return f.read()
        return None


# Global singleton instance
tts_service = TTSService()
