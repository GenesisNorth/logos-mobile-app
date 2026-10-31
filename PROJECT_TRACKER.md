# LOGOS IN ME — Project Roadmap & Progress Tracker

> **A Sacred Liturgical Rhythm for Contemplation & Scripture Dwelling**  
> *Last Updated: October 31, 2026*

---

## 1. Executive Status & Health Dashboard

| Dimension | Status | Verification Detail |
| :--- | :---: | :--- |
| **Static Code Quality** | ✅ `0 errors / 0 warnings` | Clean `flutter analyze` across all 18+ screen files |
| **Unit & Widget Tests** | ✅ `11 / 11 Passing` | Verifier, Levenshtein, Pace-Locks, Grace, 5-Week Exegesis & Week Selector |
| **Running Target** | 📱 **iPhone 17 Pro** | Running on iOS Simulator (`iOS 26.5`) with Impeller |
| **Styling & Theme** | 🎨 **Blended White-Purple** | Luminous white background with soft lavender/purple gradients |
| **Icon Suite** | ✨ **Hugeicons (Purged of AI)** | 100% stroke-rounded Hugeicons (Quill, Puzzle, Award, Praying Hands) |
| **Cloud Backend** | ☁️ **Offline-First Supabase** | Anonymous pilgrim session + Postgres sync + RLS migration |
| **Notifications** | 🔔 **Circadian & Midnight** | Lauds (7am), Sext (12pm), Vespers (9pm), Midnight Strike |
| **Speech Engine** | 🎙️ **Hybrid ($0 Cost)** | Live on-device streaming + free Groq Whisper Large V3 fallback |
| **Curriculum Pipeline** | 📖 **5 Complete Weeks** | John 15:5, Phil 4:6–7, Rom 8:1–2, Psalm 23:1–3, Col 3:1–3 with Greek/Hebrew |

---

## 2. Completed Milestones

```
 [Phase 0: Core Cloister Experience]
   ├── Onboarding & Liturgical Manifesto (Interactive Digital Covenant)
   ├── 4-Day Sacred Rhythm Architecture
   │    ├── Day 1: Cinematic Encounter & Forward-Matched Recitation
   │    ├── Day 2: Contextual Greek/Hebrew Exegesis Root Dwells
   │    ├── Day 3: Stillness Sanctuary (60s timer, 432 Hz loop, breathing pulse)
   │    └── Day 4: The Exchange (Burden Tear-Sheet Dissolve Ritual)
   ├── Midnight Pace-Lock Engine (Calendar-locked step progression)
   └── Grace Tokens & Streak Engine (3 grace tokens, guilt-free restoration)

 [Phase 1: Modern Refinement & Platform Architecture]
   ├── UI Refactoring: Luminous White & Blended Purple Gradient Design System
   ├── Universal Hugeicons Migration: Replaced all Material icons across 14 screens
   ├── Anti-AI Icon Polish: Purged sparkles/brains for sacred quills, awards & praying hands
   ├── Supabase Backend: Offline-first repository, anonymous auth, SQL migrations with RLS
   ├── Circadian Engine: NotificationService scheduling 4 liturgical hours + Midnight Bell
   └── Speech Recitation: Dual Hybrid Engine (Device streaming + Groq Whisper V3 fallback)

 [Phase 2: Multi-Week Curriculum & Interactive Exegesis]
   ├── Weeks 1–5 Scripture Exegesis Curriculum:
   │    ├── Week 1: John 15:5 (The Vine & Branches · Greek Menō)
   │    ├── Week 2: Philippians 4:6–7 (Guarding Peace · Greek Phroureō)
   │    ├── Week 3: Romans 8:1–2 (No Condemnation · Greek Katakrima)
   │    ├── Week 4: Psalm 23:1–3 (The Good Shepherd · Hebrew Yahweh Rohi & Mei Menuchot)
   │    └── Week 5: Colossians 3:1–3 (Hidden in Christ · Greek Synēgerthēte & Kekryptai)
   ├── Interactive Week Selector Modal Sheet: Browse curriculum & preview exegesis
   ├── Dynamic Scripture Card Week Plaque: Interactive pill with dropdown chevron & haptic tick
   └── End-to-end Unit & BLoC Test Coverage (11/11 tests passing)
```

---

## 3. Next Lines of Action (Prioritized Backlog)

### Priority 2: Sensory Polish & Interactive Physics (Days 3 & 4)
- [ ] **Day 4 Tear Sheet Dissolve Physics**: Add ember glowing particles, enhanced dispersion physics, and sacred audio feedback during burden release.
- [ ] **Day 3 Sacred Breath Pacer**: Synchronized 4-second box or circle breathing rhythm with dual outer glow ring expansion.
- [ ] **Liturgical Ambient Audio Player Enhancements**: Volume slider and loop controls for 432 Hz sanctuary tones.

### Priority 3: Realtime Community Rooms (Supabase Live Feeds)
- [ ] **The Well**: Connect live pastoral questions & audio replies to the `community_prayers` table.
- [ ] **Prayer Circles**: Realtime 7-day ephemeral voice note prayers using Supabase Storage.
- [ ] **Valley of Achor**: Silent candle-lighting counter synced across pilgrims worldwide.

### Priority 4: Account Upgrades & Cloud Recovery
- [ ] **Account Linking**: Allow seekers to link their anonymous UUID to Apple Sign-In or Email without losing their streak.
- [ ] **Cross-Device Sync**: Automatic restore on fresh device login.

---

## 4. Architecture Reference

```
lib/
├── core/
│   ├── config/app_config.dart                  # Build-time defines (Supabase, Groq, Stillness)
│   ├── services/
│   │   ├── audio_service.dart                  # Ambient stems & sanctuary chimes
│   │   ├── notification_service.dart           # Circadian alarms & midnight pace notifications
│   │   ├── supabase_service.dart               # Anonymous pilgrim session & Postgres client
│   │   └── speech/
│   │       ├── device_speech_recognizer.dart   # On-device 0ms streaming STT ($0)
│   │       ├── groq_whisper_service.dart       # Free Whisper Large V3 fallback
│   │       └── hybrid_speech_recognizer.dart   # Dual-engine coordinator
│   ├── theme/
│   │   ├── logos_colors.dart                   # White & blended purple design system
│   │   ├── logos_icons.dart                    # Hugeicons stroke-rounded registry
│   │   └── logos_theme.dart                    # Light Sanctuary & Examen Evening themes
│   └── utils/scripture_verifier.dart           # Levenshtein distance & pause normalization
├── features/
│   ├── journey/                                # 4-Day Sacred Rhythm & Pace Locks
│   ├── altar/                                  # Streaks, Grace Tokens, Saved Tear Sheets
│   ├── community/                              # The Well, Prayer Circles, Valley, Milestones
│   ├── exchange/                               # Day 4 Burden Dissolve Canvas
│   ├── onboarding/                             # Covenant Signature & Liturgical Manifesto
│   └── recitation/                             # Recitation Studio & Scaffolding Modes
└── supabase/
    └── migrations/20261031_logos_schema.sql    # Complete Postgres schema with RLS
```
