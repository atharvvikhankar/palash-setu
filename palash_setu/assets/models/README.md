---
license: mit
base_model: ai4bharat/indictrans2-indic-indic-dist-320M
base_model_relation: quantized
library_name: optimum
pipeline_tag: translation
tags:
  - translation
  - onnx
  - onnxruntime
  - indictrans2
  - ai4bharat
  - multilingual
language:
  - as
  - bn
  - brx
  - doi
  - en
  - gom
  - gu
  - hi
  - kn
  - ks
  - mai
  - ml
  - mr
  - mni
  - ne
  - or
  - pa
  - sa
  - sat
  - sd
  - ta
  - te
  - ur
---

# indictrans2-indic-indic-dist-320M-onnx

ONNX export of [`ai4bharat/indictrans2-indic-indic-dist-320M`](https://huggingface.co/ai4bharat/indictrans2-indic-indic-dist-320M), the
IndicTrans2 translation model from **AI4Bharat / IIT Madras**.

Direction: Indic to Indic **directly**, with no English pivot. Both `src_lang` and `tgt_lang` are Indic tags.

## Files

| File | Purpose |
|---|---|
| `encoder_model.onnx` | Encoder |
| `decoder_model.onnx` | Decoder, first step, no cache |
| `decoder_with_past_model.onnx` | Decoder, later steps, with KV cache |
| `int8/` | The same three graphs, int8 dynamic quantization |
| `model.SRC`, `model.TGT`, `dict.SRC.json`, `dict.TGT.json` | SentencePiece models and vocabularies (source and target sides are separate) |
| `configuration_indictrans.py`, `modeling_indictrans.py`, `tokenization_indictrans.py` | Custom architecture and tokenizer code, loaded with `trust_remote_code=True` |

Sizes: fp32 2.05 GB, int8 519 MB.

## Preprocessing is mandatory

IndicTrans2 does **not** take raw text. You must run `IndicProcessor` from
[IndicTransToolkit](https://github.com/VarunGumma/IndicTransToolkit) first:

```bash
pip install IndicTransToolkit optimum[onnxruntime] transformers sentencepiece
```

`IndicProcessor.preprocess_batch` normalises the script, applies Indic-specific
punctuation and numeral handling, protects entities, and **prefixes the two
language tags**. Skipping it gives silently wrong output — the model still
produces fluent-looking text, but in the wrong language or with corrupted
content.

`postprocess_batch` reverses the entity protection. It is also required.

## Language tags

The tags are plain text prefixed to the source sentence, in the order
`<src_lang> <tgt_lang> <sentence>`. `IndicProcessor` adds them for you; you only
pass `src_lang=` and `tgt_lang=`.

For example, `ip.preprocess_batch(["This is a test."], src_lang="eng_Latn",
tgt_lang="hin_Deva")` produces `"eng_Latn hin_Deva This is a test ."`.

The tags are `<iso639-3>_<ISO 15924 script>`. Languages with two scripts have two
tags. Supported tags:

| Tag | Language |
|---|---|
| `asm_Beng` | Assamese |
| `ben_Beng` | Bengali |
| `brx_Deva` | Bodo |
| `doi_Deva` | Dogri |
| `gom_Deva` | Konkani |
| `guj_Gujr` | Gujarati |
| `hin_Deva` | Hindi |
| `kan_Knda` | Kannada |
| `kas_Arab` | Kashmiri (Arabic) |
| `kas_Deva` | Kashmiri (Devanagari) |
| `mai_Deva` | Maithili |
| `mal_Mlym` | Malayalam |
| `mar_Deva` | Marathi |
| `mni_Beng` | Manipuri (Bengali) |
| `mni_Mtei` | Manipuri (Meitei) |
| `npi_Deva` | Nepali |
| `ory_Orya` | Odia |
| `pan_Guru` | Punjabi |
| `san_Deva` | Sanskrit |
| `sat_Olck` | Santali |
| `snd_Arab` | Sindhi (Arabic) |
| `snd_Deva` | Sindhi (Devanagari) |
| `tam_Taml` | Tamil |
| `tel_Telu` | Telugu |
| `urd_Arab` | Urdu |
| `eng_Latn` | English |

## Usage

```python
import torch
from transformers import AutoTokenizer
from optimum.onnxruntime import ORTModelForSeq2SeqLM
from IndicTransToolkit.processor import IndicProcessor

REPO = "TigreGotico/indictrans2-indic-indic-dist-320M-onnx"

tokenizer = AutoTokenizer.from_pretrained(REPO, trust_remote_code=True)
model = ORTModelForSeq2SeqLM.from_pretrained(REPO, trust_remote_code=True, use_cache=True)
ip = IndicProcessor(inference=True)          # REQUIRED - see "Preprocessing"

sentences = ["आज मौसम अच्छा है और बच्चे बाहर खेल रहे हैं।", "मुझे थोड़ी चीनी के साथ एक कप चाय चाहिए।"]
src_lang, tgt_lang = "hin_Deva", "tam_Taml"

batch = ip.preprocess_batch(sentences, src_lang=src_lang, tgt_lang=tgt_lang)
enc = tokenizer(batch, return_tensors="pt", padding=True, truncation=True, max_length=256)

with torch.inference_mode():
    out = model.generate(**enc, num_beams=4, max_new_tokens=64, use_cache=True)

decoded = tokenizer.batch_decode(out, skip_special_tokens=True, src=False)
print(ip.postprocess_batch(decoded, lang=tgt_lang))
```


To use the quantized graphs, pass `subfolder="int8"`.

## Sample output

| Direction | Input | Output |
|---|---|---|
| `hin_Deva` → `tam_Taml` | आज मौसम अच्छा है और बच्चे बाहर खेल रहे हैं। | இன்று வானிலை நன்றாக உள்ளது, குழந்தைகள் வெளியில் விளையாடுகிறார்கள். |
| `tam_Taml` → `ben_Beng` | எனக்கு கொஞ்சம் சர்க்கரையுடன் ஒரு கப் தேநீர் வேண்டும். | আমি একটু চিনি দিয়ে এক কাপ চা চাই। |
| `ben_Beng` → `mar_Deva` | চেন্নাই যাওয়ার ট্রেনটি তিন নম্বর প্ল্যাটফর্ম থেকে সকাল ছয়টায় ছেড়ে যায়। | चेन्नईला जाणारी ट्रेन तिसऱ्या प्लॅटफॉर्मवरून सकाळी सहा वाजता निघते. |

## Parity against the PyTorch original

10 sentences over 5 Indic languages (Hindi, Tamil, Bengali, Marathi, Malayalam),
`num_beams=4`, `max_new_tokens=64`, greedy string comparison against
`AutoModelForSeq2SeqLM.from_pretrained(..., trust_remote_code=True)`.

| Precision | Exact match |
|---|---|
| fp32 | **100%** |
| int8 | 60% |

## Limits

Maximum sequence length is 256 tokens on both sides. The sinusoidal position
table is frozen into the graph at export time, so longer inputs are not
supported. Truncate with `max_length=256`.

## Export route

Exported with `optimum.exporters.onnx.onnx_export_from_model` and a custom
`OnnxConfig` registered for the `IndicTrans` model type. The config subclasses
`M2M100OnnxConfig` and remaps the field names IndicTrans2 uses
(`encoder_embed_dim` instead of `d_model`, `encoder_vocab_size` instead of
`vocab_size`). Opset 17. Optimum validated encoder and both decoder graphs
against PyTorch at `atol=1e-3` during export.

`optimum-cli export onnx` alone does not work: it has no config for the
`IndicTrans` architecture.

## Attribution

The model is the work of [AI4Bharat](https://ai4bharat.iitm.ac.in/), IIT Madras.

```bibtex
@article{gala2023indictrans2,
  title   = {IndicTrans2: Towards High-Quality and Accessible Machine Translation Models for all 22 Scheduled Indian Languages},
  author  = {Jay Gala and Pranjal A. Chitale and Raghavan AK and Varun Gumma and Sumanth Doddapaneni and Aswanth Kumar and Janki Nawale and Anupama Sujatha and Ratish Puduppully and Vivek Raghavan and Pratyush Kumar and Mitesh M. Khapra and Raj Dabre and Anoop Kunchukuttan},
  journal = {Transactions on Machine Learning Research},
  year    = {2023}
}
```

Licence: MIT, same as the original.
