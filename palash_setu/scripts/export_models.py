import os
import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from parler_tts import ParlerTTSForConditionalGeneration

OUTPUT_DIR = "exported_models"

def export_indictrans2():
    print("Exporting IndicTrans2 (Hindi -> Indic)...")
    model_name = "ai4bharat/indictrans2-en-indic-dist-200M"
    tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_name, trust_remote_code=True)
    
    # Save base models
    model.save_pretrained(os.path.join(OUTPUT_DIR, "indictrans2-en-indic"))
    tokenizer.save_pretrained(os.path.join(OUTPUT_DIR, "indictrans2-en-indic"))
    
    print("Exporting IndicTrans2 (Indic -> Hindi)...")
    model_name_rev = "ai4bharat/indictrans2-indic-en-dist-200M"
    tokenizer_rev = AutoTokenizer.from_pretrained(model_name_rev, trust_remote_code=True)
    model_rev = AutoModelForSeq2SeqLM.from_pretrained(model_name_rev, trust_remote_code=True)
    
    model_rev.save_pretrained(os.path.join(OUTPUT_DIR, "indictrans2-indic-en"))
    tokenizer_rev.save_pretrained(os.path.join(OUTPUT_DIR, "indictrans2-indic-en"))

def export_parler_tts():
    print("Exporting Indic Parler-TTS...")
    model_name = "ai4bharat/indic-parler-tts"
    model = ParlerTTSForConditionalGeneration.from_pretrained(model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    
    model.save_pretrained(os.path.join(OUTPUT_DIR, "indic-parler-tts"))
    tokenizer.save_pretrained(os.path.join(OUTPUT_DIR, "indic-parler-tts"))

def export_indicconformer():
    print("Exporting IndicConformer...")
    # NOTE: NeMo requires specific environment setup, we will just download the NeMo checkpoints for now.
    import urllib.request
    
    hi_url = "https://huggingface.co/ai4bharat/indicconformer_stt_hi_hybrid_ctc_rnnt_large/resolve/main/model.nemo"
    sat_url = "https://huggingface.co/ai4bharat/indicconformer_stt_sat_hybrid_ctc_rnnt_large/resolve/main/model.nemo"
    
    os.makedirs(os.path.join(OUTPUT_DIR, "indicconformer"), exist_ok=True)
    
    print("Downloading Hindi Conformer...")
    urllib.request.urlretrieve(hi_url, os.path.join(OUTPUT_DIR, "indicconformer", "hi_model.nemo"))
    
    print("Downloading Santali Conformer...")
    urllib.request.urlretrieve(sat_url, os.path.join(OUTPUT_DIR, "indicconformer", "sat_model.nemo"))


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    export_indictrans2()
    export_parler_tts()
    export_indicconformer()
    print("All models exported successfully to", OUTPUT_DIR)
