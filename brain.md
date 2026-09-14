# Palash Setu - Product Requirement Document (PRD)

> **Note:** Please paste your complete PRD content in this file. Once you've added the PRD, I will analyze the requirements and break down the implementation into structured parts and action items.

---

## 1. Overview & Vision
*(Paste overview or general vision here)*

## 2. Product Requirements
*(Paste feature requirements, target audience, tech stack preferences, etc. here)*

## 3. Scope & Features
*(Paste detailed modules/features here)*

# PALASH Setu — Real-Time Vernacular Translation & Teacher Empowerment Tool

## Complete Engineering PRD

### (Full tech stack, architecture, data, API, and screen-level detail)

# ==================================================

# 0. SCOPE NOTE

# ==================================================

This is the SIH 2026 PROTOTYPE, not the final production platform. It
covers ONE tribal language end-to-end (Santali); Ho and Mundari are
UI-visible but disabled, to be filled in later via the community
correction pipeline (Section 23 roadmap). Every technical decision below
is made specifically to be demoable, offline, and honest about its limits.

# ==================================================

# 1. BACKGROUND

# ==================================================

Jharkhand's PALASH MTB-MLE programme improves foundational literacy for
tribal children, but only 23% of Grade 1 children in Jharkhand understand
Hindi, and most teachers in tribal-area schools are Hindi-medium trained
with no Ho/Mundari/Santali proficiency. Over 5,000 tribal-area primary
schools are affected. Without a technology bridge, MTB-MLE cannot scale.

# ==================================================

# 2. PROPOSED SOLUTION

# ==================================================

An app that translates Hindi into Santali (Ho/Mundari later) in text and
voice, in real time, fully offline-capable on a low-cost tablet. It
auto-generates bilingual worksheets/flashcards aligned to NIPUN Bharat
outcomes, tags every result with a confidence level, and collects
teacher/native-speaker corrections to improve over time.

# ==================================================

# 3. COMPLETE TECH STACK

# ==================================================

---

## 3.1 FRONTEND (mobile + tablet, one codebase)

---

Framework: Flutter 3.x / Dart 3.x
(single codebase for phone + tablet, good offline
storage support, small footprint on low-RAM devices)

State management: flutter_riverpod

Local database: drift (built on sqflite) — for lessons, vocabulary,
worksheets, flashcards, sync metadata

Key-value store: shared_preferences (or hive) — for settings, UI
language, content language pair, onboarding-complete flag

Networking: dio — HTTP client for sync/backend calls, with
interceptors for retry/timeout handling

Connectivity: connectivity_plus — detect online/offline state,
drives the "Offline ready" / "Needs internet" tags

Localization: flutter_localizations + intl, with .arb files for
English / Hindi / Santali UI strings

Fonts: Noto Sans + Noto Sans Devanagari + Noto Sans Ol Chiki,
bundled as app assets (not downloaded at runtime)

Audio recording: record package — mic capture for Voice Translation

Audio playback: just_audio — plays generated Santali/Hindi voice

Permissions: permission_handler — mic + storage prompts

PDF export: pdf + printing packages — worksheet/flashcard export

On-device ML: tflite_flutter (or onnxruntime for Flutter) — runs
quantized ASR/MT models on-device for offline mode, and supports a
validated lightweight TTS runtime only if such a runtime is confirmed
and selected for the target device (see Section 3.3)

---

## 3.2 BACKEND (content sync + correction collection only — not the demo's live translation path, which runs on-device)

---

Framework: FastAPI (Python 3.11+)

Server: Uvicorn (behind Nginx in deployment)

Database: PostgreSQL (content: lessons, vocabulary, outcomes) —
SQLite acceptable for the hackathon demo backend

ORM: SQLAlchemy + Alembic (migrations)

File/object storage: local filesystem for the prototype (pre-generated
audio, worksheet PDFs, icon assets); S3-compatible
storage as a drop-in swap for production

Background jobs: none required for the prototype (no live retraining);
a simple cron/manual script re-bundles a content pack
when curriculum data changes

Containerization: Docker + docker-compose for local dev and demo hosting

API docs: FastAPI's built-in OpenAPI/Swagger UI at /docs

---

## 3.3 AI / NLP MODELS (run on-device for the offline demo)

---

### ASR (speech → text):

Model: Whisper Tiny

Runtime: whisper.cpp (quantized ggml build) for on-device inference on
Android, or faster-whisper server-side for the backend/dev
environment

Language: Hindi

### Translation (text → text):

Model: IndicTrans2 (AI4Bharat), Hindi → Santali (hin_Deva → sat_Olck)

Runtime: exported/quantized to ONNX (or CTranslate2) for on-device
inference where target-device performance permits; HuggingFace
`transformers` used server-side for batch pre-translation of the
curriculum content pack

Repo: github.com/AI4Bharat/IndicTrans2

Offline strategy: pre-translated curriculum content is cached locally and
is the guaranteed offline path; new sentence translation can use the
on-device IndicTrans2 runtime where performance permits, with cached /
pre-translated content used as fallback when live on-device inference
cannot complete reliably

### TTS (text → voice):

Model: validated, pre-generated Santali audio for the prototype
curriculum, vocabulary, worksheets, and demo phrases; dynamic Santali
TTS is used only after a confirmed Santali-capable model/runtime with
suitable licensing, quality, and target-device performance is selected

Runtime: cached audio files for guaranteed offline prototype playback;
a confirmed lightweight on-device TTS runtime may be added for live
generation after validation

### Confidence scoring:

Source: model output signals calibrated against a human-verified
Hindi–Santali test set, bucketed into High / Medium / Low —
the displayed value is an estimate of translation reliability, not a
guaranteed probability or accuracy score

---

## 3.4 VERIFICATION ITEMS — DO NOT ASSUME, CONFIRM BEFORE BUILD

---

1. Confirm the Santali TTS model/runtime used for any dynamic generation actually supports Santali and has suitable licensing, quality, and target-device performance. The prototype must use validated pre-generated Santali audio where a suitable dynamic Santali TTS solution is unavailable.
2. Confirm Whisper Tiny's Hindi accuracy is acceptable for classroom background noise, not just clean audio.
3. Confirm Ol Chiki glyphs render correctly with the bundled Noto Sans Ol Chiki font on the actual demo tablet, not just in a browser/design tool.
4. Confirm on-device quantized IndicTrans2 inference speed on the target 4GB RAM tablet actually meets the latency targets in Section 11 — benchmark early, don't assume from a desktop GPU benchmark.
5. Measure the final offline content/AI package size on the target tablet after including quantized models, fonts, curriculum, vocabulary, worksheets, flashcards, and cached audio; optimize the package for the target device instead of assuming a fixed package size.

---

## 3.5 DEV TOOLS

---

Version control: Git + GitHub (required deliverable per SIH: "GitHub
repository")

CI: GitHub Actions — lint + build check on push (optional
for hackathon timeline, nice to have)

Testing (frontend): flutter_test + integration_test for the core flows in
Section 12

Testing (backend): pytest

Design handoff: Figma (white theme, components per Section 15)

# ==================================================

# 4. SYSTEM ARCHITECTURE

# ==================================================

```text
                 ┌────────────────────────┐
                 │   Flutter App (device)  │
                 │  Phone / Tablet, offline│
                 └───────────┬─────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
┌─────────▼─────────┐ ┌──────▼────────────┐ ┌────────▼──────────────┐
│ On-device ASR     │ │ On-device MT      │ │ Offline Audio / TTS   │
│ Whisper Tiny      │ │ IndicTrans2       │ │ Cached Santali audio  │
│ (ggml)            │ │                   │ │ + validated TTS       │
│                   │ │                   │ │ runtime                │
└───────────────────┘ └───────────────────┘ └────────────────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                 ┌───────────▼─────────────┐
                 │ Local DB (drift/sqflite)│
                 │ lessons, vocab, sync log│
                 └───────────┬─────────────┘
                             │
                       (only when online)
                             │
                 ┌───────────▼─────────────┐
                 │ FastAPI Backend          │
                 │ Content + Sync +         │
                 │ Correction Collection    │
                 └───────────┬─────────────┘
                             │
                 ┌───────────▼─────────────┐
                 │ PostgreSQL + File Store │
                 └─────────────────────────┘

```

The translation path used live in the classroom (ASR → MT → TTS/audio)
does not require the backend or network for supported offline content. The
backend exists only to deliver the initial content pack and to collect
correction data for later retraining. Pre-translated curriculum content
and validated Santali audio are guaranteed offline; new sentence
translation may use on-device IndicTrans2 where target-device performance
permits, otherwise the app falls back to available cached/pre-translated
content rather than depending on the network.

# ==================================================

# 5. DATA MODELS

# ==================================================

---

### TeacherProfile (local only)

---

id string (uuid, local)
name string
mobile string, optional
uiLanguage enum(en, hi, sat)
contentPair enum(hi-sat) // fixed at prototype stage
createdAt datetime

---

### Lesson

---

id string
grade int (1–3)
subject enum(language, math, evs)
type enum(lesson_script, activity, assessment_prompt)
hindiText string
santaliText string, nullable // pre-translated, cached
santaliAudioRef string, nullable // path to cached audio file
confidence enum(high, medium, low), nullable
outcomeIds string[] // NIPUN Bharat outcome tags

---

### VocabularyEntry

---

id string
hindiWord string
santaliWord string, nullable
santaliAudioRef string, nullable
iconRef string // bundled offline icon asset id
category enum(numbers, animals, classroom_objects, greetings, ...)
confidence enum(high, medium, low), nullable

---

### Worksheet

---

id string
sourceLessonId string, nullable
outcomeId string
worksheetType enum(fill_blank, match, short_answer, picture_based)
pdfRef string
createdAt datetime

---

### FlashcardDeck

---

id string
entryIds string[]
createdAt datetime

---

### CorrectionEntry (feeds the community correction loop)

---

id string
sourceText string (Hindi)
originalOutput string (Santali, as generated)
correctedOutput string (Santali, as corrected by teacher/native speaker)
correctorType enum(teacher, native_speaker)
syncedToServer bool
createdAt datetime

---

### SyncPack (metadata for offline delta sync)

---

id string
grade int
subject string
contentHash string
downloadedAt datetime
sizeBytes int

# ==================================================

# 6. LOCAL (OFFLINE) DATABASE — TABLE LIST

# ==================================================

teacher_profile (single row, local device)

lessons

vocabulary_entries

worksheets

flashcard_decks

flashcard_deck_entries (join table)

correction_entries

sync_packs

app_settings (key-value: ui_language, content_pair, text_size,
onboarding_complete)

# ==================================================

# 7. BACKEND API CONTRACTS

# ==================================================

---

### CONTENT

---

GET /lessons?grade=&subject=&type=
→ 200: [ { id, grade, subject, type, hindiText, outcomeIds } ]

GET /lessons/{id}
→ 200: { id, hindiText, santaliText, confidence, audioUrl }

GET /vocabulary
→ 200: [ { id, hindiWord, category } ]

GET /outcomes
→ 200: [ { id, code, description } ] // NIPUN Bharat outcome list

---

### SYNC

---

GET /sync/manifest?since={timestamp}
→ 200: { packs: [ { id, grade, subject, contentHash, sizeBytes } ] }

GET /sync/pack/{packId}
→ 200: binary bundle (lessons + pre-translated text + pre-generated
audio + icon refs for that grade/subject)

---

### CORRECTIONS (community-sourced corpus building)

---

POST /corrections
body: { sourceText, originalOutput, correctedOutput, correctorType }
→ 201: { id, receivedAt }

This endpoint only stores data for later human review/retraining — it does
NOT trigger any live model update in the prototype.

---

### WORKSHEET / FLASHCARD GENERATION (used only when source content isn't already cached on-device)

---

POST /worksheets/generate
body: { lessonId | hindiText, outcomeId, worksheetType }
→ 200: { pdfUrl }

POST /flashcards/generate
body: { wordListId | hindiWords: string[] }
→ 200: { entries: [ { hindiWord, santaliWord, audioUrl, iconRef,
confidence } ] }

---

### ERROR SHAPE (all endpoints)

---

```json
{
  "success": false,
  "error": {
    "code": "SANTALI_TTS_UNAVAILABLE",
    "message": "Santali voice generation is temporarily unavailable."
  }
}

```

Error codes used throughout: ASR_UNAVAILABLE, SANTALI_ASR_UNAVAILABLE,
TRANSLATION_UNAVAILABLE, SANTALI_TTS_UNAVAILABLE, HINDI_TTS_UNAVAILABLE,
INVALID_AUDIO, NETWORK_FAILURE, TIMEOUT, MODEL_LOADING,
INSUFFICIENT_RESOURCES, CONTENT_NOT_SYNCED.

# ==================================================

# 8. ON-DEVICE VOICE TRANSLATION ORCHESTRATOR (pseudocode)

# ==================================================

```text
function voiceTranslate(audioClip):
    startTimer()
    hindiText = whisperTiny.transcribe(audioClip)         // ASR
    asrTime = elapsed()

    result = indicTrans2.translate(hindiText, "hin_Deva", "sat_Olck")
    santaliText = result.text
    confidence = calibratedConfidence(result)              // High/Med/Low
    mtTime = elapsed()

    audio = santaliAudioCache.get(santaliText)
    if audio == null and validatedSantaliTTS.isAvailable():
        audio = validatedSantaliTTS.synthesize(santaliText, voice="sat-IN")
    if audio == null:
        return error("SANTALI_TTS_UNAVAILABLE")
    ttsTime = elapsed()

    return {
      success: true,
      sourceText: hindiText,
      translatedText: santaliText,
      confidence: confidence,
      audio: audio,
      latency: { asr: asrTime, translation: mtTime, tts: ttsTime,
                 total: asrTime + mtTime + ttsTime }
    }

```

For supported offline curriculum/demo phrases, validated cached Santali
audio is used. For new sentences, dynamic Santali TTS is used only when a
validated Santali-capable runtime is installed and available on the
target device. If no audio path is available, return the matching error
code from Section 7 — never substitute a fake result.

# ==================================================

# 9. APP LANGUAGES

# ==================================================

UI language and content translation pair, at prototype stage:

English · Hindi · Santali (Ol Chiki)

Ho and Mundari: visible in every picker, disabled, "Coming soon".

# ==================================================

# 10. COMPLETE APP FLOW

# ==================================================

Splash → Simple Login → Language Selection → Home Dashboard

---

### SPLASH

---

Logo centered, white background, ~1–2 sec, loads local DB, checks
onboarding_complete flag in app_settings to decide next screen on
subsequent launches (returning users skip straight to Home).

---

### SIMPLE LOGIN

---

Fields: Name (required), Mobile (optional)

Button: Continue

No password, no OTP. Writes TeacherProfile locally, sets
onboarding_complete = false until language is also chosen.

---

### LANGUAGE SELECTION

---

Five options rendered (English, Hindi, Santali enabled; Ho, Mundari
visibly disabled). Tap → writes ui_language + content_pair to
app_settings, sets onboarding_complete = true, navigates to Home.

---

### HOME DASHBOARD

---

Greeting with teacher name, current content pair with a "change" link,
three primary buttons (Voice Translate, Text Translate, Worksheet &
Flashcards), an Offline/Online status chip driven by connectivity_plus,
and a Settings icon (top-right).

---

### VOICE TRANSLATE

---

Direction switch (⇅) → mic button → processing state chain (Listening /
Understanding / Translating / Generating voice / Ready) → transcript +
translation + confidence badge + phonetic guide → play/replay button →
measured latency readout. Calls voiceTranslate() from Section 8.

---

### TEXT TRANSLATE

---

Direction switch → text input → Translate button → result + confidence
badge + phonetic guide → Listen button. Calls translate() +
textToSpeech() individually (no ASR stage).

---

### WORKSHEET & FLASHCARDS

---

Topic dropdown (pre-loaded demo set) → type toggle (Worksheet /
Flashcards) → Generate → preview (bilingual, per-item audio) → Export/
Print. Reads from the local cached Lesson/VocabularyEntry tables first;
falls back to the backend generation endpoints (Section 7) only if
content isn't cached and the device is online.

---

### SETTINGS

---

App Language, Translation Direction, Text Size, About. Any change writes
straight to app_settings and reflects immediately, no restart.

# ==================================================

# 11. PERFORMANCE / LATENCY TARGETS

# ==================================================

Common/cached phrases: < 0.5 sec

Classroom target: ≤ 3 sec (headline demo target)

New/complex sentences: ~5–8 sec (shown honestly, not hidden)

Every screen that shows a translation must display the REAL measured
total latency, computed exactly as in Section 8 — never hardcoded.

# ==================================================

# 12. TESTING CHECKLIST

# ==================================================

* Splash → Login → Language → Home flow works on first install
* Returning launch skips straight to Home
* Voice Translate produces real transcript, translation, confidence, and audio for at least 10 test classroom sentences
* Text Translate direction switch (⇅) correctly swaps source/target
* Worksheet export produces a valid, openable PDF
* Flashcard deck plays correct audio per card
* App fully usable with device in airplane mode, using pre-synced content
* Settings language change re-renders all visible screens without restart
* Layout verified on at least one phone-size and one tablet-size screen, portrait and landscape
* Every error path (mic denied, TTS unavailable, no network) shows a plain-language message, never a stack trace
* Latency numbers shown on-screen match what's logged internally (no discrepancy between displayed and actual)

# ==================================================

# 13. FOLDER STRUCTURE (indicative)

# ==================================================

```text
palash_setu/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── routes/
│   │   ├── services/
│   │   └── theme/
│   ├── features/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── translation/
│   │   ├── voice_translation/
│   │   ├── lessons/
│   │   ├── flashcards/
│   │   ├── worksheets/
│   │   └── settings/
│   ├── shared/
│   │   ├── widgets/
│   │   └── models/
│   └── main.dart
├── assets/
│   ├── fonts/
│   ├── icons/
│   └── models/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── core/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   └── main.py
│   ├── tests/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
├── docs/
├── test/
├── android/
├── ios/
├── pubspec.yaml
├── README.md
└── .gitignore

```

# ==================================================

# 14. DESIGN SYSTEM

# ==================================================

Background: #FFFFFF

Primary text: #1A1A1A

Accent (primary actions): one single accent colour, e.g. #1B6FB0, used
only for Translate / Play / Generate buttons

Confidence badges: High = #2E7D32 (green), Medium = #F9A825 (amber),
Low = #C62828 (red) — used nowhere else in the UI

Font: Noto Sans family (+ Devanagari + Ol Chiki variants)

Base text size: 16sp, scalable via Settings (Small/Medium/Large)

Touch targets: minimum 48dp phone, 56–64dp tablet, mic button largest
element on its screen

# ==================================================

# 15. RESPONSIVE BREAKPOINTS

# ==================================================

< 600dp width (phone): single column, bottom-anchored primary button

≥ 600dp width (tablet): Home's 3 buttons in a row; Voice/Text screens
centered with side margins instead of full width

Portrait + landscape both supported on tablet.

# ==================================================

# 16. SAFETY FIRST — EXPLICIT REQUIREMENT

# ==================================================

Safety and responsible use are mandatory requirements of PALASH Setu,
especially because the application is designed for primary education and
classroom use.

1. **No Fake AI Results**

   * The app must never display fabricated translation, transcription,
     audio, confidence, latency, or synchronization results.
   * If an AI model or required resource is unavailable, the app must
     clearly show an appropriate error or fallback state.

2. **Translation Reliability**

   * Every AI-generated translation must include a calibrated
     High / Medium / Low reliability indicator where applicable.
   * The confidence indicator represents an estimated reliability level,
     not a guaranteed probability or translation accuracy.
   * Low-confidence translations must be clearly identifiable to the
     teacher.

3. **Human Verification**

   * Important educational content should be reviewed by teachers or
     qualified native speakers before being treated as verified
     curriculum content.
   * Teacher/native-speaker corrections must be collected through the
     correction pipeline and must not automatically modify the
     production model.

4. **Safe Failure & Fallback**

   * If ASR, translation, TTS, or another required component fails, the
     app must fail safely.
   * The app must provide a clear, teacher-friendly message instead of
     displaying incorrect content.
   * Cached/pretranslated curriculum and validated cached audio should be
     used as the offline fallback where available.
   * The app must never pretend that a server-dependent operation
     succeeded while offline.

5. **Educational Safety**

   * Preloaded curriculum content must be reviewed before inclusion in
     the demo content pack.
   * Generated worksheets, flashcards, translations, and educational
     material must remain within the selected curriculum context.
   * The system must avoid presenting uncertain AI-generated content as
     authoritative educational fact.

6. **Microphone & Audio Safety**

   * Microphone access must require the appropriate device permission.
   * Recording should occur only when the teacher starts the voice
     interaction.
   * The app must provide a clear visual recording/listening state.
   * The app must not silently record in the background.

7. **Privacy by Design**

   * No student personally identifiable information (PII) should be
     required for core functionality.
   * Voice recordings should not be permanently stored unless explicitly
     required by a future feature and approved by the project
     requirements.
   * API keys, credentials, and private backend configuration must never
     be embedded in the Flutter application.

8. **Accessibility & User Safety**

   * Important states must use both text and visual indicators; color
     alone must never communicate a critical state.
   * Error messages must use simple language suitable for non-technical
     teachers.
   * Primary actions such as microphone, stop, play, and retry must have
     sufficiently large touch targets.
   * The app must remain usable on supported phone and tablet screen
     sizes.

9. **Safety Testing**

   * Test microphone permission denial.
   * Test invalid/corrupted audio.
   * Test ASR failure.
   * Test translation/model failure.
   * Test TTS unavailability.
   * Test offline/network failure.
   * Test insufficient device resources.
   * Test missing or corrupted offline content.
   * Test that no fake result is shown after any failure.

**Safety Principle:**

> **When PALASH Setu is uncertain, unavailable, or unable to verify a
> result, it must clearly say so rather than pretending to be correct.**

# ==================================================

# 17. SECURITY & PRIVACY

# ==================================================

* No student PII collected anywhere in the app
* TeacherProfile stored locally only; not transmitted unless a future sync feature is explicitly built
* Backend credentials/API keys never embedded in the Flutter app
* HTTPS required for all backend calls (sync, corrections, generation)
* CorrectionEntry data anonymized (no student identifiers) before any future retraining use

# ==================================================

# 18. ACCESSIBILITY

# ==================================================

* Adjustable text size (Settings)
* High-contrast white theme by default
* Icon + label pairing everywhere, never icon-only
* Voice-first primary interaction, reducing reliance on reading/typing

# ==================================================

# 19. IMPLEMENTATION PHASES

# ==================================================

PHASE 1 Splash + Simple Login + Language Selection + Home shell

PHASE 2 Text Translate, wired to on-device IndicTrans2 + validated
Santali cached audio / confirmed Santali TTS runtime

PHASE 3 Voice Translate, wired to Whisper Tiny → IndicTrans2 →
validated Santali cached audio / confirmed Santali TTS runtime

PHASE 4 Confidence scoring + phonetic guide display

PHASE 5 Offline content cache + Settings

PHASE 6 Worksheet & Flashcard generation (from pre-loaded demo set)

PHASE 7 Backend: content API, sync API, correction endpoint

PHASE 8 Responsive polish (phone/tablet), latency + error-path hardening

# ==================================================

# 20. ACCEPTANCE CRITERIA

# ==================================================

✓ Full flow: Splash → Simple Login → Language Selection → Home

✓ English / Hindi / Santali UI, switchable anytime

✓ Voice + Text translation both use the real on-device ASR/MT/TTS or
validated cached-audio stack named in Section 3, with real measured
latency shown every time

✓ Every translation carries a real High/Medium/Low confidence badge
calibrated against a human-verified Hindi–Santali test set

✓ Santali output includes a phonetic guide

✓ Worksheet/Flashcard generation produces real bilingual output

✓ App fully functional offline using the on-device cache

✓ White, high-contrast, large-touch-target UI throughout

✓ Correct layout on both phone- and tablet-sized screens

✓ No fake/mocked translation, audio, confidence, or latency anywhere

# ==================================================

# 21. IMPORTANT ANTIGRAVITY INSTRUCTIONS

# ==================================================

1. Inspect any existing project work and reuse it — don't rebuild from scratch.
2. Use exactly the stack in Section 3 — Flutter/Dart frontend, FastAPI
   backend, Whisper Tiny + IndicTrans2 + validated Santali cached audio /
   confirmed Santali TTS runtime. Do not substitute a general-purpose LLM
   for translation.
3. Complete Section 3.4's verification items before wiring any model into
   the UI; report plainly if a dynamic Santali TTS model/runtime isn't
   actually available. Use validated pre-generated Santali audio for the
   prototype where dynamic TTS is unavailable.
4. Keep login (Section 10) minimal — no password/OTP infrastructure.
5. Keep Ho and Mundari visible-but-disabled everywhere.
6. Never fake latency, confidence, sync status, or translation output.
7. Build one responsive Flutter codebase for phone and tablet — no forks.

# ==================================================

# 22. OUT OF SCOPE FOR THIS PROTOTYPE

# ==================================================

* Full Ho/Mundari model support
* Real account-based authentication
* Admin/NGO review dashboard for corrections
* Free-form (non-pre-loaded) content generation
* Multi-state scaling (Odisha, WB, Chhattisgarh)
* "Teach the Teacher" mode
* Live on-device retraining from corrections

# ==================================================

# 23. ROADMAP (post-hackathon, not built now)

# ==================================================

* Turn CorrectionEntry data into a real retraining pipeline for Santali, then extend the same pipeline to Ho and Mundari
* Replace Simple Login with school-linked authentication
* Build the NGO/admin correction-review dashboard
* Open free-form lesson translation beyond the pre-loaded demo set
* Formal certification on 2GB RAM devices per the original problem statement's minimum spec
* "Teach the Teacher" mode to reduce long-term tool dependency
* Expand to Odisha, West Bengal, Chhattisgarh tribal languages

# ==================================================

# SHORT SUMMARY

# ==================================================

Frontend: Flutter/Dart, riverpod, drift (local DB), dio, Noto fonts

Backend: FastAPI, PostgreSQL, SQLAlchemy, Docker

ASR: Whisper Tiny (on-device, whisper.cpp)

MT: IndicTrans2 (on-device, ONNX/CTranslate2 where performance
permits; cached/pre-translated curriculum for guaranteed offline use)

TTS: Validated pre-generated Santali audio for the prototype;
confirmed Santali-capable TTS runtime for live generation only
after validation

Languages: English / Hindi / Santali now, Ho / Mundari later

Flow: Splash → Simple Login → Language Selection → Home

Theme: white, high-contrast, large touch targets, confidence badges

Offline: Preloaded offline content/AI package containing quantized models,
fonts, curriculum, vocabulary, worksheets, flashcards, and
cached audio; final package size measured and optimized on the
target tablet

Latency: <0.5s cached, ≤3s target, 5–8s worst case — always real,
never faked

## Voice-to-Voice Model Implementation Spec

---

## Overview of the Pipeline

Two independent conversion chains, each with 3 stages: **ASR → MT → TTS**.

```
DIRECTION 1 — Teacher speaks Hindi, student hears Santhali:
  Hindi audio → [ASR: IndicConformer-Hindi] → Hindi text
             → [MT: IndicTrans2-Distilled-320M] → Santhali text
             → [TTS: Indic Parler-TTS] → Santhali audio

DIRECTION 2 — Student speaks Santhali, teacher hears Hindi:
  Santhali audio → [ASR: IndicConformer-Santali] → Santhali text
                → [MT: IndicTrans2-Distilled-320M] → Hindi text
                → [TTS: Indic Parler-TTS] → Hindi audio
```

---

## Stage 1: Speech-to-Text (ASR)

### Model: IndicConformer (AI4Bharat)
Both Hindi and Santhali use the **same model family** — monolingual IndicConformer checkpoints, one per language. This matters: it means a single, consistent ASR architecture handles both directions, not two unrelated tools.

| Language | HuggingFace repo | Architecture | Params | File size |
|---|---|---|---|---|
| Hindi | `ai4bharat/indicconformer_stt_hi_hybrid_ctc_rnnt_large` | Conformer-Large, Hybrid CTC-RNNT | 120M | ~480 MB (fp32 checkpoint) |
| Santhali (Santali) | `ai4bharat/indicconformer_stt_sat_hybrid_ctc_rnnt_large` | Conformer-Large, Hybrid CTC-RNNT | 120M | ~523 MB (fp32 checkpoint) |

**Note:** these are official AI4Bharat pre-trained models — a native Santali ASR checkpoint already exists, so no fine-tuning is required for the prototype. (Quantize to int8 before shipping — see Quantization section below to bring these down to the target on-device footprint.)

**Library required:** AI4Bharat NeMo toolkit (fork of NVIDIA NeMo)
```bash
git clone https://github.com/AI4Bharat/NeMo.git && cd NeMo && git checkout nemo-v2 && bash reinstall.sh
```

**Input format:** 16,000 Hz, mono-channel WAV audio
```bash
ffmpeg -i input.wav -ac 1 -ar 16000 input_ready.wav
```

**Inference code (per language, swap repo id for Hindi vs Santali):**
```python
import torch
import nemo.collections.asr as nemo_asr

model = nemo_asr.models.ASRModel.from_pretrained(
    "ai4bharat/indicconformer_stt_hi_hybrid_ctc_rnnt_large"  # or _sat_ for Santhali
)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.freeze()
model = model.to(device)

model.cur_decoder = "rnnt"  # RNNT decoder recommended for streaming/real-time use
transcript = model.transcribe(["input_ready.wav"], batch_size=1)[0]
```

**Output:** plain transcribed text string.

---

## Stage 2: Machine Translation (MT)

### Model: IndicTrans2 — Distilled 320M variant (AI4Bharat, IIT Madras)

**Explicitly use the distilled variant, not the base 1.1B model** — this is the single most important spec detail; using the wrong checkpoint blows the RAM budget.

| Field | Value |
|---|---|
| HuggingFace repo (Indic→En direction) | `ai4bharat/indictrans2-indic-en-dist-200M` |
| HuggingFace repo (En→Indic direction) | `ai4bharat/indictrans2-en-indic-dist-200M` |
| Params | ~200–320M (distilled) |
| Size after int8 quantization | ~300 MB |
| Supported direction for this app | Hindi ↔ Santali (`sat_Olck` — Ol Chiki script tag) |

**Note on directionality:** IndicTrans2 ships as **direction-specific models** (En/Hindi→Indic vs Indic→En/Hindi) — you need both the `en-indic` and `indic-en` distilled checkpoints loaded to cover both translation directions in your pipeline (Hindi→Santali uses the en-indic-family model treating Hindi as source; Santali→Hindi uses the indic-en-family model).

**Library required:**
```bash
pip install IndicTransToolkit
```

**Inference code:**
```python
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from IndicTransToolkit.processor import IndicProcessor

ip = IndicProcessor(inference=True)

# Hindi -> Santali
model_name = "ai4bharat/indictrans2-en-indic-dist-200M"
tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name, trust_remote_code=True)

src_lang, tgt_lang = "hin_Deva", "sat_Olck"
batch = ip.preprocess_batch([hindi_text], src_lang=src_lang, tgt_lang=tgt_lang)
inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True)
outputs = model.generate(**inputs, max_length=256, num_beams=5)
translated = ip.postprocess_batch(tokenizer.batch_decode(outputs, skip_special_tokens=True), lang=tgt_lang)
```

**Language tags used:** `hin_Deva` (Hindi, Devanagari script), `sat_Olck` (Santali, Ol Chiki script).

**Output:** translated text string in target language/script.

---

## Stage 3: Text-to-Speech (TTS)

### Model: Indic Parler-TTS (AI4Bharat / Parler ecosystem)

Chosen over Coqui TTS because Coqui's company shut down (Dec 2023/Jan 2024) and is no longer officially maintained; Indic Parler-TTS is actively maintained and purpose-built for Indian languages.

| Field | Value |
|---|---|
| HuggingFace repo | `ai4bharat/indic-parler-tts` |
| Size (quantized) | ~40 MB per voice |
| Languages | Hindi + multiple Indic languages (verify Santali voice coverage at build time — if unavailable, budget for a small amount of native-speaker recording to bootstrap a Santali voice) |

**Inference code (indicative — confirm exact API at build time against current model card):**
```python
from parler_tts import ParlerTTSForConditionalGeneration
from transformers import AutoTokenizer
import soundfile as sf

model = ParlerTTSForConditionalGeneration.from_pretrained("ai4bharat/indic-parler-tts")
tokenizer = AutoTokenizer.from_pretrained("ai4bharat/indic-parler-tts")

description = "A clear, natural Hindi voice, moderate pace, classroom-appropriate tone."
input_ids = tokenizer(description, return_tensors="pt").input_ids
prompt_ids = tokenizer(translated_text, return_tensors="pt").input_ids

generation = model.generate(input_ids=input_ids, prompt_input_ids=prompt_ids)
sf.write("output.wav", generation.cpu().numpy().squeeze(), model.config.sampling_rate)
```

**Output:** WAV audio file, played back to the listener.

---

## Quantization (applies to all three stages)

All models above are listed at their base/fp32 checkpoint size. **Convert every model to int8 (or int4 where quality allows) before on-device deployment** — this is what brings the combined footprint down to the ~550–600MB target stated in the PRD. Recommended tooling: `onnxruntime` quantization tools or `bitsandbytes` for PyTorch-based int8 conversion, depending on final mobile runtime chosen (ONNX Runtime Mobile vs PyTorch Mobile/ExecuTorch).

---

## Latency Optimization: Phrase-Bank Pre-Computation

For the ~200–300 core classroom phrases identified as high-frequency:
1. Run the full ASR → MT → TTS pipeline once per phrase during the one-time content sync
2. Cache both the translated text and the generated TTS audio file locally
3. At runtime, check incoming (recognized) text against the phrase-bank cache first — on a match, play the cached audio directly, skipping MT + TTS inference entirely
4. Only fall through to live MT + TTS inference for free-form/uncommon input, where the UI shows a "processing…" state

---

## Confidence Scoring

- IndicConformer's CTC/RNNT decoder outputs per-token log-probabilities; aggregate these into a per-utterance confidence score
- IndicTrans2's beam search (`num_beams=5` above) exposes sequence-level score/log-likelihood from the top beam
- Combine ASR confidence × MT confidence into a single bucketed score (High/Medium/Low) using thresholds to be calibrated during testing
- Below the "Medium" threshold, flag the output in the UI for teacher verification before use

---

## Worksheet/Flashcard Generation (No LLM)

Explicitly **not** using any generative LLM (Sarvam-1, Qwen2.5-0.5B, or otherwise) for this component — both were evaluated and rejected as unnecessary RAM risk on a 2GB device (see PRD Section 7.2). Instead:
1. Translated sentence/phrase output from Stage 2 is slotted into pre-built worksheet/flashcard templates
2. Templates are tagged to NIPUN Bharat learning outcomes at design time (not inferred by a model at runtime)
3. This is a deterministic string-substitution + layout step, not an ML inference step — zero additional model footprint

---

## Summary Table — What Antigravity Needs to Build

| Component | Exact model/repo | Library | Input | Output |
|---|---|---|---|---|
| Hindi ASR | `ai4bharat/indicconformer_stt_hi_hybrid_ctc_rnnt_large` | AI4Bharat NeMo | 16kHz mono WAV | Hindi text |
| Santali ASR | `ai4bharat/indicconformer_stt_sat_hybrid_ctc_rnnt_large` | AI4Bharat NeMo | 16kHz mono WAV | Santali text |
| Hindi→Indic MT | `ai4bharat/indictrans2-en-indic-dist-200M` | IndicTransToolkit + transformers | Hindi text (`hin_Deva`) | Santali text (`sat_Olck`) |
| Indic→Hindi MT | `ai4bharat/indictrans2-indic-en-dist-200M` | IndicTransToolkit + transformers | Santali text (`sat_Olck`) | Hindi text (`hin_Deva`) |
| TTS (both languages) | `ai4bharat/indic-parler-tts` | parler_tts + transformers | Text + voice description | WAV audio |