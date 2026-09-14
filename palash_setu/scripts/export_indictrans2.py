import os
import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

model_id = "ai4bharat/indictrans2-indic-indic-dist-320M"
save_dir = "models/indictrans2_int8"
os.makedirs(save_dir, exist_ok=True)

print(f"Downloading {model_id}...")
print("This will take a significant amount of time and memory.")

try:
    # Load tokenizer and model
    tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_id, trust_remote_code=True)
    
    print("Model downloaded successfully!")
    
    # Save the standard PyTorch model first
    tokenizer.save_pretrained(save_dir)
    model.save_pretrained(save_dir)
    print(f"PyTorch model saved to {save_dir}")
    
    # Optional: Apply PyTorch Dynamic Quantization for memory reduction (CPU only)
    print("Applying PyTorch INT8 Dynamic Quantization...")
    quantized_model = torch.quantization.quantize_dynamic(
        model, {torch.nn.Linear}, dtype=torch.qint8
    )
    
    quantized_save_dir = f"{save_dir}_quantized"
    os.makedirs(quantized_save_dir, exist_ok=True)
    tokenizer.save_pretrained(quantized_save_dir)
    torch.save(quantized_model.state_dict(), os.path.join(quantized_save_dir, "pytorch_model.bin"))
    
    print(f"Quantized model saved to {quantized_save_dir}")
    print("Export process complete!")
    
except Exception as e:
    print(f"Error during export: {e}")
