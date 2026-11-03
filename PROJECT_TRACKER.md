# LOGOS IN ME — Project Roadmap & Progress Tracker

> **A Sacred Liturgical Rhythm for Contemplation & Scripture Dwelling**  
> *Last Updated: October 31, 2026*

---

## 1. Executive Status & Health Dashboard

| Dimension | Status | Verification Detail |
| :--- | :---: | :--- |
| **Static Code Quality** | ✅ `0 errors / 0 warnings` | Clean `flutter analyze` across all 22+ screen & service files |
| **Unit & Widget Tests** | ✅ `26 / 26 Passing` | Verifier, Pace-Locks, Grace, Exegesis, Community, Soundscapes, APNS, Packs, Widgets, Multi-Translation |
| **Running Target** | 📱 **iPhone 17 Pro** | Running on iOS Simulator (`iOS 26.5`) with Impeller |
| **Styling & Theme** | 🎨 **Blended White-Purple** | Luminous white background with soft lavender/purple gradients |
| **Icon Suite** | ✨ **Hugeicons (Purged of AI)** | 100% stroke-rounded Hugeicons (Quill, Puzzle, Award, Praying Hands, Books) |
| **Cloud Backend** | ☁️ **Offline-First Supabase** | Anonymous pilgrim session + Postgres sync + APNS device token sync + RLS |
| **Notifications** | 🔔 **Circadian & APNS Cloud** | Lauds (7am), Sext (12pm), Vespers (9pm), Midnight Bell + APNS token sync |
| **iOS Widgets & Island**| 📲 **Live Activity Ready** | Dynamic Island pill + 2x2 Small + 4x2 Medium + Lock Screen preview & sync |
| **Translations** | 📖 **ESV, KJV, NASB, NIV** | Multi-translation bridge with live recitation target switching |
| **App Store Compliance**| 🛡️ **Privacy Manifest Ready** | `PrivacyInfo.xcprivacy` with UserDefaults, FileTimestamp, BootTime declarations |
| **Curriculum Pipeline** | 📖 **52-Week Scripture Packs** | Offline pack downloader with seasonal bundles (Weeks 1–4, 5–8, 9–12, 13–16) |
| **Community Feeds** | 🕊️ **Live & Cached Rooms** | The Well pastoral watch, Prayer Circles voice notes, Valley of Achor rooms |

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

 [Phase 3: Sensory Polish & Sacred Physics]
   ├── Day 4 Holy Altar Dissolution: 160 glowing embers, sinusoidal thermal lift, and holy shockwave
   ├── Progressive Altar Haptics: Progressive ember crackles at 25%, 50%, 75% + bronze sanctuary chime
   ├── Relic Tear Sheet Reveal: Smooth entrance animation with golden ambient halo
   ├── Day 3 Sacred Breath Pacer: 16s Cloister rhythm (Inhale 4s · Hold 4s · Exhale 4s · Rest 4s)
   ├── Dynamic Breathing Aura: Multi-layer luminous violet and golden halos with sinusoidal hold shimmer
   ├── Liturgical Phase Badge: Real-time phase pill cues with haptic bead ticks at each boundary
   └── 432 Hz Soundscape Controller: Interactive intensity slider modal sheet (0-100%)

 [Phase 4: Realtime Community Rooms & Pastoral Care]
   ├── CommunityRepository Architecture: Dual-layer offline cache + live Supabase table sync
   ├── The Well Pastoral Watch: Live petition submission, 4-hour SLA watch, pastoral audio responses
   ├── Prayer Circles: Ephemeral 7-day voice note prayers synced to community feeds
   ├── Valley of Achor: Themed quiet lament rooms with Scripture anchors & candle solidarity counter
   └── Comprehensive BLoC & Community Unit Tests (13/13 tests passing)
4. **Cloud Recovery, Account Upgrades & Data Export (Completed)**
   ├── Anonymous Pilgrim Session -> Email/Password Account Linking (`SupabaseService.linkWithEmail`)
   ├── Spiritual Relic Journal & Covenant Export via `SharePlus` (UUID, Streaks, Roots, Tear Sheets)
   ├── Fast-Access Pilgrim Account Sheet accessible from the top-left Sanctuary Cloister Avatar
   ├── Dedicated Cloud Recovery dialog in Prayer Altar with real-time status and offline fallback
   ├── Direct 5-Week Scripture Curriculum Cloister bottom sheet selector
   ├── Zero layout overflows on all device viewports (responsive flex headers & settings tiles)
   └── Automated Navigation & Integration Test Suite (15/15 tests passing, 0 analyzer issues)
5. **Sensory Depth & Contemplative Stems (Completed)**
   ├── Multi-Track Ambient Stem Engine (`AudioService` with concurrent loop synchronizer)
   ├── Bundled Contemplative Audio Stems (`ambient_sanctuary_dawn.wav`, `ambient_gentle_rain.wav`, `ambient_gregorian_resonance.wav`)
   ├── Sacred Soundscape Console bottom sheet with 3 independent stem sliders & master intensity
   ├── Atmospheric Soundscape Presets: Sanctuary Dawn, Cloister Rain, Gregorian Choir
   ├── Liturgical Haptic Feedback Engine: real-time `wordProgressTick` on speech matches, triple-cadence `sacredCelebrationHaptic`, `liturgicalHourChime`
   └── Comprehensive Unit & Widget Test Suite (18/18 tests passing, 0 analyzer issues)
6. **APNS Token Cloud Sync & Offline Scripture Packs (Completed)**
   ├── Remote APNS Push Notification Sync with Supabase Postgres schema migration (`device_push_tokens`)
   ├── Deterministic 64-character APNS token generation, local persistence, and offline fallback
   ├── Sanctuary Liturgical Schedule dialog with APNS Token status & Cloud Sync trigger
   ├── Altar Screen APNS Push Notification Service live status tile
   ├── Offline Scripture Pack Architecture (`ScripturePack`, `ScripturePackRepository`)
   ├── 52-Week Seasonal Scripture Packs (Foundation of Peace, Heavenly Ascent, Wisdom in Cloister, Pilgrim Eternal)
   ├── Full Modal Bottom Sheet `ScripturePacksSheet` with real-time progress indicators & storage freeing
   ├── Fast entry points from Curriculum Week Selector and Altar Screen settings
   └── 100% Automated Unit & Widget Test Suite (21/21 tests passing, 0 analyzer issues)
7. **Liturgical iOS Widgets, Dynamic Island & App Store Compliance (Completed)**
   ├── Official Apple Privacy Manifest (`ios/Runner/PrivacyInfo.xcprivacy`) for App Store compliance
   ├── iOS Background Modes configured (`audio`, `fetch`, `remote-notification` in `Info.plist`)
   ├── `LiturgicalWidgetService` & `LiturgicalWidgetData` model computing Circadian hour & countdown
   ├── Real-time payload serialization into shared preferences for iOS WidgetKit
   ├── `LiturgicalWidgetPreviewSheet` interactive modal for Dynamic Island (expandable pill), Small (2x2), Medium (4x2), and Lock Screen widgets
   ├── Single-tap "Sync Current State to iOS Widget" action with haptic response and sync badge
   └── Comprehensive Unit & Widget Test Suite (23/23 tests passing, 0 analyzer issues)
8. **Scripture Multi-Translation Bridge (ESV, KJV, NASB, NIV) (Completed)**
   ├── Complete multi-translation mappings populated across all 5 weeks for ESV, KJV, NASB, and NIV
   ├── `ScriptureDrop.withTranslation(key)` model transformation preserving exegesis & audio metadata
   ├── Interactive Sanctuary Hero Card `[ESV ▾]` pill trigger with dropdown chevron and haptic tick
   ├── `_showTranslationSelectorSheet` modal featuring translation attributes, live verse preview, and selection state
   ├── Real-time target text propagation to Day 1 Oral Recitation (Levenshtein engine), Day 3 Stillness, Day 4 Exchange, and Home Screen Widgets
   ├── Translation choice persisted across sessions and automatically applied when advancing curriculum weeks
   └── Comprehensive Unit & Widget Test Suite (26/26 tests passing, 0 analyzer issues)
9. **Contemplative Audio Stem Expansion (5 Stems & 5 Presets) (Completed)**
   ├── Synthesized and bundled 10-second seamless loops: `ambient_night_breeze.wav` and `ambient_sanctuary_bells.wav` (22050 Hz @ 432 Hz resonance)
   ├── Expanded `AudioService` with 5 synchronized audio players: Drone, Rain, Resonance, Night Breeze, and Sanctuary Bells
   ├── 5 Atmospheric Presets: Sanctuary Dawn, Cloister Rain, Gregorian Choir, Midnight Examen, and Apostolic Sabbath
   ├── Upgraded `StillnessSanctuaryScreen` Soundscape Console sheet with adaptive scroll view, custom stem colors, and Hugeicons
   └── Full automated unit & widget test coverage for all 5 stems, volume controls, and presets
```

---

## 3. Next Lines of Action (Prioritized Backlog)

### Priority 10: App Store Release Pre-Flight & Presentation Package
- [ ] **Production Archive & Release Pre-Flight**: Run release compilation checks (`flutter build ipa --no-codesign` and `flutter build appbundle --release`), verifying ProGuard shrink rules and iOS bundle integrity.
- [ ] **App Store Marketing Presentation Package**: 6.7" & 6.1" liturgical screenshot set showcasing the 4-Day Sacred Rhythm, Soundscape Console, Translation Bridge, and Community rooms.



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
