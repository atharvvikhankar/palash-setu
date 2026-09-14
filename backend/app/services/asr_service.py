"""
ASR Service — IndicConformer via NeMo
=====================================
Transcribes Hindi and Santali speech audio to text for the PALASH Setu pipeline.

Model: ai4bharat/indicconformer_stt_hi_hybrid_ctc_rnnt_large
Runtime: AI4Bharat NeMo
"""

import asyncio
import io
import os
import tempfile
import logging
import time
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)

@dataclass
class ASRResult:
    text: str
    language: str
    latency_ms: float


class ASRService:
    """Lazy-loading IndicConformer ASR singleton. Model loads on first call."""

    def __init__(self):
        self._models = {}
        self._load_error: Optional[str] = None
        self._lock = asyncio.Lock()

    def _load_model(self, language: str):
        """Load IndicConformer model for a specific language (hi or sat)."""
        if language in self._models:
            return
            
        try:
            import torch
            import nemo.collections.asr as nemo_asr
            logger.info(f"Loading IndicConformer model for {language}…")
            t0 = time.time()
            
            repo_id = f"ai4bharat/indicconformer_stt_{language}_hybrid_ctc_rnnt_large"
            model = nemo_asr.models.ASRModel.from_pretrained(repo_id)
            device = torch.device("cpu")
            model.freeze()
            model = model.to(device)
            model.cur_decoder = "rnnt"
            
            self._models[language] = model
            elapsed = round((time.time() - t0) * 1000)
            logger.info(f"IndicConformer ({language}) loaded in {elapsed}ms")
        except Exception as e:
            self._load_error = str(e)
            logger.error(f"IndicConformer load failed: {e}")

    @property
    def is_loaded(self) -> bool:
        return len(self._models) > 0

    @property
    def load_error(self) -> Optional[str]:
        return self._load_error

    async def transcribe_bytes(self, audio_bytes: bytes, language: str = "hi") -> ASRResult:
        """
        Transcribe raw audio bytes (WAV/MP3/PCM) to text.
        """
        # Ensure 'hi' or 'sat'
        if language not in ("hi", "sat"):
            language = "hi"
            
        async with self._lock:
            if language not in self._models:
                loop = asyncio.get_running_loop()
                await loop.run_in_executor(None, self._load_model, language)

        if self._load_error:
            raise RuntimeError(f"ASR model not available: {self._load_error}")

        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(None, self._transcribe_sync, audio_bytes, language)
        return result

    def _transcribe_sync(self, audio_bytes: bytes, language: str) -> ASRResult:
        """Synchronous transcription (run in executor thread)."""
        import soundfile as sf
        import numpy as np
        
        t0 = time.time()
        
        # We need to save to a 16kHz mono WAV file for NeMo
        audio_buf = io.BytesIO(audio_bytes)
        try:
            audio_arr, sample_rate = sf.read(audio_buf, dtype="float32", always_2d=False)
        except Exception:
            audio_arr = np.frombuffer(audio_bytes, dtype=np.float32)
            sample_rate = 16000

        if sample_rate != 16000:
            import librosa
            audio_arr = librosa.resample(audio_arr, orig_sr=sample_rate, target_sr=16000)

        # Handle stereo to mono
        if len(audio_arr.shape) > 1:
            audio_arr = audio_arr.mean(axis=1)

        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp_path = tmp.name
        
        try:
            sf.write(tmp_path, audio_arr, 16000)
            
            model = self._models[language]
            # NeMo returns a list of lists of strings, or just list of strings
            result = model.transcribe([tmp_path], batch_size=1)
            
            if isinstance(result, tuple):
                result = result[0] # transcribe() can return tuple depending on NeMo version
                
            full_text = result[0] if len(result) > 0 else ""
            if isinstance(full_text, list):
                full_text = " ".join(full_text)
                
            latency_ms = round((time.time() - t0) * 1000, 1)
            logger.info(f"ASR ({language}): '{full_text}' ({latency_ms}ms)")
            
            return ASRResult(
                text=full_text.strip() or "(no speech detected)",
                language=language,
                latency_ms=latency_ms,
            )
        finally:
            os.remove(tmp_path)

# Module-level singleton
asr_service = ASRService()
