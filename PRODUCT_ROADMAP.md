# LOGOS IN ME — v1 Product Roadmap & Progress

> Source: full product/UX review on the Android emulator, 2026-11-08.
> Status keys: `[x]` done · `[~]` in progress · `[ ]` not started.
> Phase A = client-only work, no backend needed. Phase B = needs Supabase + admin.

---

## Decisions (2026-11-08)

| Topic | Decision |
| :--- | :--- |
| **Community v1** | Ship **Prayer Circles**, **In the Valley**, **The Well**. Hide **Study Pods**, **Voice Comfort**, **Milestones / Streak Family** behind feature flags until there are real users and content (admin can switch them on). |
| **The Well** | No guaranteed reply time. Petitions go to a pastoral inbox in the admin; replies come from users with the *pastor* role. A crisis notice is always shown. |
| **Translations** | Offer as many as possible. 13 public-domain / open-licence texts are fetched from bible.helloao.org (`tool/fetch_translations.py`). ESV, NIV, NASB are kept under the publishers' quotation allowance with notices — **a publisher licence must be confirmed before commercial launch**. |
| **Verse audio** | On-device text-to-speech now (free, offline). Recorded readings later via admin uploads. |
| **Admin** | A web admin console is required to populate content and manage features (spec below). The app reads feature flags and content from Supabase with local defaults. |

---

## Phase A — Client (no backend)

### P0 · Trust, safety, integrity
- [x] Grace tokens only bridge a missed calendar day for the streak; no picking days, never complete unfinished content
- [x] Week picker cannot jump weeks mid-rhythm (would mix progress between verses)
- [x] Feature-flag service with local defaults (admin-overridable later)
- [x] Hide Study Pods, Voice Comfort, Milestones, Streak Family behind flags
- [x] The Well: remove "guaranteed 4h / ordained pastors" promise and Cal.com stub; honest copy
- [x] Crisis notice (not an emergency service + crisis line) on The Well and In the Valley
- [x] Valley: remove fake "Pastoral Oversight" label; add report / hide on posts (local until backend)
- [x] Scripture packs: stop the simulated download; show honest "coming soon"
- [x] Translation copyright notices screen

### P1 · Core experience
- [x] 16 translations, grouped picker with live preview
- [x] Fix truncated ESV Psalm 23:1-3
- [x] Verse text-to-speech ("Listen") on home and in the recitation studio, in the selected translation
- [x] Settings screen: reminders (on/off + times), translation, voice speed, theme, account name, legal, about
- [x] Altar = progress only; remove developer diagnostics (APNS, UUID, iOS widget on Android, SHA-256)
- [x] Edit display name
- [x] Onboarding: translation choice, reminder permission priming, honest copy, consistent typography, no truncation
- [x] "Today" status on home: what to do now / done-for-today with unlock countdown
- [x] Branded launch screen (Android + iOS)

### Found & fixed during Phase A
- [x] Reminders fired in UTC (`tz.local` never set) — now uses the device time zone
- [x] 4 notifications/day incl. 12:01 AM → one daily reminder at a chosen time + optional 9 PM reflection
- [x] Removed `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` / unused foreground-service permissions (Play policy risk)
- [x] Fonts were downloaded at runtime (wrong font offline / first launch) → bundled in `assets/google_fonts/` with OFL licences
- [x] App icon and launch screen were Flutter defaults → placeholder brand mark (`tool/make_brand_assets.py`; replace with designer art)
- [x] The Exchange was pre-filled with someone else's burden; empty burdens can no longer be "laid down"; real burden hashed
- [x] Day 3 "Recite" button was white-on-white (invisible)
- [x] Grace/rename/erase: new Settings actions; erase clears all on-device data

### P2 · Polish & standards
- [x] Copy cleanup: remove "neural pathways", "scientifically structured", "full-bleed", "sacred neural match", "Cloister UUID"
- [x] Grace card quiet state at 0 tokens; empty Tear Sheets icon
- [x] Header liturgical hour label matches the schedule
- [x] Accessibility: semantic labels on icon-only buttons; tap alternative to drag in The Exchange
- [x] Consistent dialogs (app-styled) for grace & manual input
- [ ] Share verse as an image card
- [ ] Continue splitting `lib/main.dart` (translation picker, settings, reminders, Today card extracted; home screen still ~2,200 lines)
- [ ] Hidden-keyboard verse shrink in recitation studio

---

## Phase B — Backend + Admin

- [ ] Supabase project credentials in `.env`; run `supabase/setup_complete.sql`; `tool/verify_supabase.dart`
- [ ] RLS: The Well returns only the author's own petitions (+ pastors)
- [ ] Remote feature flags & config table → app `FeatureFlags`
- [ ] Remote weekly content (drops, translations, cards) with offline cache
- [ ] Prayer Circles: upload voice notes to Storage; server-side 7-day purge (cron)
- [ ] Community: report / block / hide APIs; moderation queue; keyword filter
- [ ] The Well pastoral inbox + responses + push to the petitioner
- [ ] Account: email link / sign-in, sign-out, **account deletion** (App Store requirement)
- [ ] Real push notifications (FCM + APNs) — replace generated APNS token
- [ ] `transcribe-recitation` edge function (or drop config if Groq suffices)
- [ ] Real scripture pack downloads
- [ ] Privacy policy & terms hosted; URLs in remote config
- [ ] Publisher licences: ESV (Crossway), NIV (Biblica), NASB (Lockman)
- [ ] iOS WidgetKit extension (currently preview-only)

---

## Admin Console — Requirements

A web console (recommended: Next.js + Supabase Auth, same Postgres with RLS; privileged writes via edge functions). Everything the app shows that is not user-generated should be editable here.

### Roles
| Role | Can |
| :--- | :--- |
| **Owner / super admin** | Everything, incl. roles, flags, deletion |
| **Content editor** | Weekly content, translations, packs, audio library |
| **Pastor** | The Well inbox: read petitions, respond, mark answered/escalate |
| **Moderator** | Community queues: reports, hide/remove, suspend users, filters |

### Modules
1. **Weekly content (curriculum)**
   - CRUD weekly drops: reference, verse texts per translation (auto-fill open translations via the helloao API; manual entry for licensed), Day 1 encounter lines/video, Day 2 context cards, Day 3 ambient preset, Day 4 prompts
   - Ordering, scheduling, draft → review → publish, preview as the app renders it
   - Seasonal packs (group weeks, publish downloadable bundles)
2. **Translations**
   - Enable/disable per translation and per region; licence status; copyright notice text
3. **Feature flags & remote config**
   - Room toggles (Study Pods, Voice Comfort, Milestones, Streak Family, The Well, Valley, Prayer Circles)
   - Grace token allowance, stillness seconds, recitation pass threshold
   - Crisis resources per country (name, phone, text, URL)
   - Legal URLs (privacy, terms), support email, minimum app version / force update, maintenance banner
4. **The Well — pastoral inbox**
   - Queue of petitions (private), assign to pastor, respond (text, later audio), mark answered
   - Crisis keyword detection → flagged as urgent; escalation notes
   - Response-time targets per team (shown in-app only if met)
5. **Community moderation**
   - Report queue (Valley, Prayer Circles, Study Pods), hide/remove, warn/suspend/ban
   - Keyword/phrase filter list, auto-hide after N reports
   - Voice note review (listen, remove); 7-day retention dashboard
6. **Voice Comfort library**
   - Upload recorded verse readings, tag by verse/theme/reader, approve, publish
7. **Notifications**
   - Default reminder times, broadcast/scheduled messages, templates, audience targeting
8. **Users**
   - Search, view progress/streak, reset progress, grant grace tokens, role assignment
   - Data export and account deletion requests (GDPR / App Store)
9. **Analytics**
   - Active users, Day 1→4 completion funnel, recitation pass rate per week & translation, retention, community activity, report volume
10. **Audit log** — every admin action (who, what, when, before/after)

### App hooks required (client side)
- [x] `FeatureFlags` with local defaults → swap source to Supabase `app_config`
- [ ] Content repository reading Supabase drops with cache (keeps bundled fallback)
- [ ] Report endpoint for posts / voice notes
- [ ] Pastor responses delivered to The Well history + push
- [ ] Crisis resources from remote config by locale

---

## Change log
- **2026-11-08** — Review completed; decisions recorded; Phase A started.
- **2026-11-09** — Phase A complete except share-image card, further `main.dart` split, keyboard verse shrink. 70 tests passing; Android AAB + iOS release builds verified; walked through on the emulator as a new user.
