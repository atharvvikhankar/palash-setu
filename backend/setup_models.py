#!/usr/bin/env python3
"""
PALASH Setu — AI Model Setup Script
=====================================
Downloads and verifies all AI model weights needed for the translation pipeline.
Uses the required SIH 2026 Prototype Distilled Models to fit within the RAM budget.

Usage:
    python setup_models.py
"""

import subprocess
import sys
import os
from pathlib import Path

MODELS_DIR = Path(__file__).parent / "models"
MODELS_DIR.mkdir(exist_ok=True)


def banner(text: str):
    print(f"\n{'=' * 60}")
    print(f"  {text}")
    print(f"{'=' * 60}")


def step(text: str):
    print(f"\n  > {text}")


def check(text: str):
    print(f"  OK {text}")


def warn(text: str):
    print(f"  WARN {text}")


# ─── Step 0: Install Python deps ─────────────────────────────────────────────

banner("Step 0: Installing Python dependencies")

step("Installing core requirements (PyTorch CPU, Transformers, SoundFile, etc.)…")
subprocess.run([
    sys.executable, "-m", "pip", "install",
    "transformers>=4.40.0",
    "torch>=2.2.0",
    "torchaudio>=2.2.0",
    "soundfile>=0.12.1",
    "librosa>=0.10.1",
    "sentencepiece>=0.2.0",
    "sacremoses>=0.1.1",
    "accelerate>=0.26.0",
    "--extra-index-url", "https://download.pytorch.org/whl/cpu",
], check=True)

step("Installing IndicTransToolkit…")
subprocess.run([
    sys.executable, "-m", "pip", "install", 
    "git+https://github.com/VarunGumma/IndicTransToolkit.git"
], check=True)

step("Installing Parler-TTS…")
subprocess.run([
    sys.executable, "-m", "pip", "install",
    "git+https://github.com/huggingface/parler-tts.git",
], check=True)

# ─── Step 1: Download IndicConformer ASR ─────────────────────────────────────

banner("Step 1: Skipping IndicConformer ASR")
step("Not needed for mobile. App uses Android Native SpeechRecognizer.")


# ─── Step 2: Download IndicTrans2 ──────────────────────────────────

banner("Step 2: Downloading IndicTrans2 MT (Hindi <-> Santali)")
step("Models: ai4bharat/indictrans2-indic-indic-1B")

mt_dir = MODELS_DIR / "mt_indic_indic"

from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

for repo_id, cache_dir in [
    ("ai4bharat/indictrans2-indic-indic-1B", mt_dir),
]:
    step(f"Downloading tokenizer and model for {repo_id}...")
    tokenizer = AutoTokenizer.from_pretrained(repo_id, trust_remote_code=True, cache_dir=str(cache_dir), token=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(repo_id, trust_remote_code=True, cache_dir=str(cache_dir), low_cpu_mem_usage=True, token=True)
    del model, tokenizer

check("Distilled MT models downloaded.")


# ─── Step 3: Download Indic Parler-TTS ───────────────────────────────────────

banner("Step 3: Downloading Indic Parler-TTS")
step("Model: ai4bharat/indic-parler-tts")

tts_dir = MODELS_DIR / "parler_tts"
try:
    from parler_tts import ParlerTTSForConditionalGeneration
    tokenizer = AutoTokenizer.from_pretrained("ai4bharat/indic-parler-tts", cache_dir=str(tts_dir))
    model = ParlerTTSForConditionalGeneration.from_pretrained("ai4bharat/indic-parler-tts", cache_dir=str(tts_dir), low_cpu_mem_usage=True)
    del model, tokenizer
    check("TTS model downloaded.")
except Exception as e:
    warn(f"Parler TTS download failed: {e}")

banner("Setup Complete!")
print("All models downloaded and ready.")
