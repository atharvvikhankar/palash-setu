import os
import urllib.request
import time

model_id = "ai4bharat/indictrans2-indic-indic-dist-320M"
save_dir = "models/indictrans2_pytorch"
os.makedirs(save_dir, exist_ok=True)

base_url = f"https://huggingface.co/{model_id}/resolve/main/"

files_to_download = [
    "config.json",
    "configuration_indictrans.py",
    "dict.SRC.json",
    "dict.TGT.json",
    "generation_config.json",
    "model.SRC",
    "model.TGT",
    "model.safetensors",
    "modeling_indictrans.py",
    "special_tokens_map.json",
    "tokenization_indictrans.py",
    "tokenizer_config.json"
]

def download_file(filename):
    url = base_url + filename
    dest_path = os.path.join(save_dir, filename)
    
    if os.path.exists(dest_path):
        print(f"[{filename}] already exists, skipping.")
        return
        
    print(f"\nDownloading: {filename}")
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            total_size = int(response.headers.get('content-length', 0))
            
            with open(dest_path, 'wb') as out_file:
                downloaded = 0
                block_size = 1024 * 1024 # 1MB blocks
                
                start_time = time.time()
                last_print_time = start_time
                
                while True:
                    buffer = response.read(block_size)
                    if not buffer:
                        break
                    out_file.write(buffer)
                    downloaded += len(buffer)
                    
                    current_time = time.time()
                    if total_size > 0 and (current_time - last_print_time > 2.0):
                        percent = (downloaded / total_size) * 100
                        mb_downloaded = downloaded / (1024*1024)
                        mb_total = total_size / (1024*1024)
                        print(f"[{filename}] {percent:.1f}% ({mb_downloaded:.1f}MB / {mb_total:.1f}MB)")
                        last_print_time = current_time
                        
        print(f"[{filename}] Download complete!")
    except Exception as e:
        print(f"Failed to download {filename}: {e}")
        if os.path.exists(dest_path):
            os.remove(dest_path)

print(f"Starting direct download of {model_id}...")
for f in files_to_download:
    download_file(f)
print("\nAll files downloaded successfully to:", save_dir)
