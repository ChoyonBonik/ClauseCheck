# ClauseCheck 🛡️

An AI-powered contract, lease, and policy scanner for Android & iOS built with Flutter and Google Gemini.

---

## 📁 Project Structure

```
clause_check/
├── backend/                   # Node.js + Express + Gemini 3.5 Flash API Service
│   ├── server.js              # Server handling multimodal uploads & Gemini prompt
│   ├── package.json           # Dependencies (@google/generative-ai, multer, express)
│   └── .env.example           # API key configuration
├── lib/
│   ├── main.dart              # Flutter application entry & dark theme
│   ├── models/
│   │   └── scan_result.dart   # Structured schema for risk score, red flags & counter-proposals
│   ├── screens/
│   │   ├── home_screen.dart   # Dashboard with PDF upload, Camera scan & Text input
│   │   ├── result_screen.dart # Visual risk score meter, red flags & disclaimer
│   │   └── paywall_screen.dart# Monetization paywall with weekly & annual plans
│   └── services/
│       ├── api_service.dart   # Multi-candidate API client communicating with backend
│       └── storage_service.dart# SharedPreferences for free scan limits & PRO status
└── android/                   # Android manifest with Camera and Internet permissions
```

---

## 🚀 Quick Start

### 1. Setup & Start Backend
```bash
cd backend
cp .env.example .env
# Edit .env and paste your GEMINI_API_KEY from Google AI Studio (https://aistudio.google.com/)
npm install
node server.js
```
The server will start at `http://localhost:3000`.

### 2. Run the Flutter Mobile App
```bash
# In the project root directory
flutter pub get
flutter run
```

---

## 💰 Monetization Model
* **Free Tier:** 2 free contract scans to experience value and establish trust.
* **Paywall:** Triggered on 3rd scan:
  * Weekly Subscription with 3-day trial: **$4.99 / week**
  * Annual Pass: **$39.99 / year**
* **Local Test:** Clicking "Start Trial" in `PaywallScreen` automatically enables PRO mode for testing without requiring live Play Store credentials.
