<div align="center">
  <h1>PALASH Setu</h1>
  <p><strong>Real-Time Vernacular Translation & Teacher Empowerment Platform</strong></p>
</div>

## Overview

PALASH Setu is a comprehensive offline-first application designed to bridge language barriers in early childhood education. Developed to support Mother Tongue-Based Multilingual Education (MTB-MLE), the platform enables real-time translation between mainstream educational languages (such as Hindi) and local vernaculars (such as Santali). 

By providing seamless, on-device translation and automated learning material generation, PALASH Setu empowers educators to deliver instruction in the language their students understand best, ensuring equitable access to foundational literacy.

## Key Features

- **Real-Time Voice & Text Translation:** High-accuracy, low-latency translation specifically tailored for educational contexts.
- **Offline-First Architecture:** Core translation and Text-to-Speech (TTS) engines run entirely on-device, ensuring uninterrupted functionality in low-connectivity environments.
- **Automated Material Generation:** Instantly creates bilingual worksheets and flashcards aligned with standardized educational frameworks.
- **Community-Driven Refinement:** Built-in mechanisms for native speakers and educators to correct and improve translation accuracy over time.
- **Cross-Platform Compatibility:** A single, responsive codebase optimized for both mobile devices and tablets.

## Technology Stack

### Client Application
- **Framework:** Flutter (Dart)
- **Local Storage:** Drift (SQLite), Shared Preferences
- **Audio Processing:** On-device capture and playback management
- **On-Device ML:** Embedded models for offline inference

### Backend Services
- **Framework:** Python / FastAPI
- **Model Deployment:** Custom ONNX models for specialized vernacular translation

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.8.1`)
- Python 3.10 or higher (for backend services)
- Android Studio or Xcode (for emulator/device testing)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/atharvvikhankar/palash-setu.git
   cd palash-setu
   ```

2. **Setup the Backend (Optional for offline features):**
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```

3. **Run the Application:**
   ```bash
   cd ../palash_setu
   flutter pub get
   flutter run
   ```

## Roadmap

- **Current:** Complete Santali (Ol Chiki) end-to-end integration.
- **Upcoming:** Expand support to additional vernacular languages including Ho and Mundari.
- **Future:** Scale community correction pipeline and deploy advanced contextual models.

## Contributing

We welcome contributions from developers, linguists, and educators. 

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/Enhancement`)
3. Commit your Changes (`git commit -m 'feat: add new enhancement'`)
4. Push to the Branch (`git push origin feature/Enhancement`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.
