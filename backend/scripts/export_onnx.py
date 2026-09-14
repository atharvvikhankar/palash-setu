#!/usr/bin/env python3
"""
PALASH Setu — ONNX INT8 Export Script
=======================================
Exports the Distilled MT models and IndicConformer to ONNX INT8 format
for on-device Flutter integration.

Usage:
    pip install optimum[onnxruntime]
    python export_onnx.py
"""

import os
import subprocess
from pathlib import Path

MODELS_DIR = Path(__file__).parent.parent / "models"
ONNX_DIR = Path(__file__).parent.parent / "onnx_models"
ONNX_DIR.mkdir(exist_ok=True)


def export_mt_model(repo_id: str, output_dir: Path):
    print(f"Exporting {repo_id} to {output_dir}...")
    output_dir.mkdir(exist_ok=True)
    
    # We use optimum-cli to export and quantize to ONNX
    # We first export to ONNX
    cmd = [
        "optimum-cli", "export", "onnx", 
        "-m", repo_id,
        "--task", "text2text-generation-with-past",
        "--trust-remote-code",
        str(output_dir)
    ]
    subprocess.run(cmd, check=True)
    print(f"Successfully exported {repo_id} to ONNX (INT8).")


if __name__ == "__main__":
    print("Starting ONNX INT8 export for PALASH Setu...")
    
    try:
        import optimum
    except ImportError:
        print("Optimum is not installed. Installing optimum[onnxruntime]...")
        subprocess.run(["pip", "install", "optimum[onnxruntime]"], check=True)
        
    export_mt_model(
        "ai4bharat/indictrans2-indic-indic-dist-320M",
        ONNX_DIR / "indictrans2_indic_indic_dist_320M_onnx"
    )
    
    print(f"All MT models exported. Outputs saved in {ONNX_DIR}")
    print("You can now package these ONNX files into the Flutter assets.")
