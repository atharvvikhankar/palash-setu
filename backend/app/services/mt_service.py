"""
MT Service — IndicTrans2 Distilled (AI4Bharat)
==============================================
Translates Hindi ↔ Santali Ol Chiki for the PALASH Setu pipeline.

Models: 
- ai4bharat/indictrans2-indic-indic-dist-320M (hi <-> sat)
Runtime: HuggingFace Transformers
"""

import asyncio
import logging
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

MODELS_DIR = Path(__file__).parent.parent.parent / "models"


@dataclass
class MTResult:
    translated_text: str
    src_lang: str
    tgt_lang: str
    confidence: str          # 'high', 'medium', 'low'
    confidence_score: float  # 0.0–1.0
    latency_ms: float
    model_used: str


class MTService:
    """Lazy-loading IndicTrans2 MT singleton."""

    def __init__(self):
        self._tokenizers = {}
        self._models = {}
        self._ip = None
        self._load_error: Optional[str] = None
        self._lock = asyncio.Lock()


    def _load_model(self, direction: str):
        """Load IndicTrans2 distilled model for a specific direction."""
        repo_id = "ai4bharat/indictrans2-indic-indic-1B"
        
        if repo_id in self._models:
            return

        try:
            from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
        except ImportError:
            self._load_error = "transformers not installed."
            return

        try:
            from IndicTransToolkit import IndicProcessor
            if self._ip is None:
                self._ip = IndicProcessor(inference=True)
        except ImportError:
            self._load_error = "IndicTransToolkit not installed."
            return

        try:
            logger.info(f"Loading IndicTrans2 model '{repo_id}'…")
            t0 = time.time()

            cache_dir = str(MODELS_DIR / ("mt_hi_sat" if direction == "en-indic" else "mt_sat_hi"))

            tokenizer = AutoTokenizer.from_pretrained(
                repo_id,
                trust_remote_code=True,
                cache_dir=cache_dir,
                token=True,
            )
            model = AutoModelForSeq2SeqLM.from_pretrained(
                repo_id,
                trust_remote_code=True,
                cache_dir=cache_dir,
                low_cpu_mem_usage=True,
                token=True,
            )
            model.eval()

            self._tokenizers[repo_id] = tokenizer
            self._models[repo_id] = model

            elapsed = round((time.time() - t0) * 1000)
            logger.info(f"IndicTrans2 ({repo_id}) loaded in {elapsed}ms")
        except Exception as e:
            self._load_error = str(e)
            logger.error(f"IndicTrans2 load failed: {e}")


    @property
    def is_loaded(self) -> bool:
        return len(self._models) > 0

    @property
    def load_error(self) -> Optional[str]:
        return self._load_error

    async def translate(
        self,
        text: str,
        src_lang: str = "hin_Deva",
        tgt_lang: str = "sat_Olck",
    ) -> MTResult:
        """Translate text. Runs IndicTrans2 in a thread pool executor."""
        
        # Determine direction
        # en-indic covers English/Hindi -> Indic
        # For Hindi to Santali and vice versa, we use indic-indic
        direction = "indic-indic"
        repo_id = "ai4bharat/indictrans2-indic-indic-1B"

        async with self._lock:
            if repo_id not in self._models:
                loop = asyncio.get_running_loop()
                await loop.run_in_executor(None, self._load_model, direction)

        if self._load_error:
            raise RuntimeError(f"MT model not available: {self._load_error}")

        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(
            None, self._translate_sync, text, src_lang, tgt_lang, repo_id
        )
        return result

    def _translate_sync(self, text: str, src_lang: str, tgt_lang: str, repo_id: str) -> MTResult:
        """Synchronous IndicTrans2 inference (run in thread executor)."""
        import torch

        t0 = time.time()
        
        tokenizer = self._tokenizers[repo_id]
        model = self._models[repo_id]

        batch = self._ip.preprocess_batch([text], src_lang=src_lang, tgt_lang=tgt_lang)

        inputs = tokenizer(
            batch,
            truncation=True,
            padding="longest",
            return_tensors="pt",
            return_attention_mask=True,
        )

        with torch.no_grad():
            generated = model.generate(
                **inputs,
                num_beams=5,
                num_return_sequences=1,
                max_length=256,
                output_scores=True,
                return_dict_in_generate=True,
            )

        raw_output = tokenizer.batch_decode(
            generated.sequences,
            skip_special_tokens=True,
            clean_up_tokenization_spaces=True,
        )

        translations = self._ip.postprocess_batch(raw_output, lang=tgt_lang)
        translated_text = translations[0] if translations else "(translation failed)"

        confidence_score = 0.85 
        try:
            import math
            if generated.sequences_scores is not None:
                seq_score = generated.sequences_scores[0].item()
                confidence_score = min(1.0, math.exp(seq_score))
        except Exception:
            pass

        if confidence_score >= 0.7:
            confidence_label = "high"
        elif confidence_score >= 0.4:
            confidence_label = "medium"
        else:
            confidence_label = "low"

        latency_ms = round((time.time() - t0) * 1000, 1)
        logger.info(
            f"MT: '{text[:40]}' → '{translated_text[:40]}' "
            f"(conf={confidence_score:.2f}, {latency_ms}ms)"
        )

        return MTResult(
            translated_text=translated_text,
            src_lang=src_lang,
            tgt_lang=tgt_lang,
            confidence=confidence_label,
            confidence_score=round(confidence_score, 3),
            latency_ms=latency_ms,
            model_used=repo_id,
        )


# Module-level singleton
mt_service = MTService()
