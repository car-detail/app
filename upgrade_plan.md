# Cahrz Upgrade Plan

**Goal:** Vendors (car wash / detailing) can easily onboard, and manage their services, packages, and daily offers. Users can easily browse nearby vendors and book them with zero scheduling conflicts — all wrapped in a modern, fun, responsive UI.

**Scope:** 3 repos —
- `cahrz/app` — Vendor app (this repo)
- `cahrz/app-user` — Customer app
- `cahrz/cahrz-api` — Backend

**Status legend:** ✅ Done · 🟡 In Progress · ⬜ Not Started · 🔒 Blocked

---

## Current State (baseline, as of 2026-08-16)

| Area | State |
|---|---|
| Booking conflict prevention (backend) | ✅ Done — vendor hours check, slot capacity, duplicate-booking rejection in `bookings.service.ts` |
| Nearby vendor search (backend + user app) | ✅ Done — lat/long/radius queries, category filter, zoom-based radius |
| Vendor onboarding flow | 🟡 Exists but duplicated 3x, unclear which is live |
| Services / packages / offers management | 🟡 Exists, functional, UI not modern |
| Modern/fun UI | ⬜ Not started — no animation lib, no design system, no theming layer |
| State management | ⬜ Not started — raw `setState`, God-Activity files up to 3,200 lines |
| Automated tests | ⬜ Not started — 1 test file for ~50k LOC vendor app |
| Git hygiene | 🟡 Large uncommitted mixed changeset in working tree |

---

## Phase 0 — Cleanup & Foundation
*Do not build new UI on top of unresolved duplication and untracked churn.*

| # | Task | Repo | Status |
|---|---|---|---|
| 0.1 | Commit or discard the current uncommitted changeset (audio files, manifest edits, deleted iOS project files) so we start from a clean tree | app | ⬜ |
| 0.2 | Identify which vendor-registration screen is actually wired into navigation (`simple_add_shop_activity.dart` vs `ultra_simple_vendor_registration.dart` vs `edit_vendor_activity.dart`) | app | ⬜ |
| 0.3 | Delete the dead/superseded onboarding variants once confirmed | app | ⬜ |
| 0.4 | Audit other duplicated screens (`enhanced_offer_screen.dart` vs `enhanced_offer_list_screen.dart`, etc.) and remove dead ones | app | ⬜ |
| 0.5 | Add `flutter analyze` + a stricter lint set (enable `avoid_print`, `prefer_const_constructors`, etc.) to CI | app, app-user | ⬜ |
| 0.6 | Set up CI (GitHub Actions or similar) running analyze + tests on PRs | app, app-user, cahrz-api | ⬜ |

---

## Phase 1 — Architecture Upgrade
*Fix the structural issue (one giant low-cohesion blob, 2000–3200 line files) before adding features on top of it.*

| # | Task | Repo | Status |
|---|---|---|---|
| 1.1 | Pick a state management approach (Riverpod recommended — testable, no BuildContext coupling) | app, app-user | ⬜ |
| 1.2 | Define a shared design-system package/module: colors, typography, spacing, reusable components (buttons, cards, chips, bottom sheets) | app, app-user | ⬜ |
| 1.3 | Extract business logic out of the largest Activities into services/notifiers, one screen at a time, starting with the top 3 offenders (`profile_vendor_list_activity.dart` 3216 LOC, `simple_add_shop_activity.dart` 3149 LOC, `home_activity.dart` 2707 LOC) | app | ⬜ |
| 1.4 | Split each extracted screen into sub-widgets (target: no single file > ~400 LOC) | app | ⬜ |
| 1.5 | Standardize API layer (typed responses, consistent error handling) replacing ad-hoc calls in `ApiFuntion.dart` | app, app-user | ⬜ |
| 1.6 | Move hardcoded base URL / environment config into build flavors (dev/staging/prod), remove commented-out URL history from `Constant.dart` | app, app-user | ⬜ |

---

## Phase 2 — Vendor Onboarding UX Overhaul
*"Easily onboard themselves" is the first vendor-facing promise — make it a guided flow, not a form dump.*

| # | Task | Repo | Status |
|---|---|---|---|
| 2.1 | Design a step-by-step onboarding wizard (business info → location → hours/slot capacity → first service → first package → done) with progress indicator | app | ⬜ |
| 2.2 | Replace the single mega-form with the wizard, using the new design system | app | ⬜ |
| 2.3 | Add inline validation + friendly error states (no silent failures) | app | ⬜ |
| 2.4 | Add "resume later" support (save draft progress) | app, cahrz-api | ⬜ |
| 2.5 | Post-onboarding checklist / empty states nudging vendor to add services, packages, first offer | app | ⬜ |

---

## Phase 3 — Vendor Daily Management UX
*Services, packages, daily offers need to be fast to update — vendors will do this often.*

| # | Task | Repo | Status |
|---|---|---|---|
| 3.1 | Redesign services/packages list screens with the new component library (cards, quick-edit, toggle active/inactive) | app | ⬜ |
| 3.2 | Add a "Today's Offer" quick-create flow (minimal taps: pick service/package, discount, duration) | app | ⬜ |
| 3.3 | Dashboard summary: today's bookings, slot fill rate, active offers at a glance | app | ⬜ |
| 3.4 | Booking management screen: accept/reschedule/cancel with clear conflict/capacity feedback surfaced from backend errors | app | ⬜ |

---

## Phase 4 — Customer Browse & Booking UX
*"Easily browse and choose nearby vendor, book without conflict."*

| # | Task | Repo | Status |
|---|---|---|---|
| 4.1 | Redesign home/browse screen: map + list toggle, nearby vendors sorted by distance, category filters | app-user | ⬜ |
| 4.2 | Vendor detail screen: services, packages, live offers, ratings, operating hours, slot availability preview | app-user | ⬜ |
| 4.3 | Booking flow: date → time slot (show remaining capacity per slot from backend) → service/package → confirm | app-user | ⬜ |
| 4.4 | Surface backend conflict errors (full slot, outside hours, duplicate booking) as clear, friendly in-flow messages rather than generic errors | app-user | ⬜ |
| 4.5 | Booking history / status tracking (upcoming, past, cancelled) with reschedule/cancel actions | app-user | ⬜ |

---

## Phase 5 — Modern & Fun UI Polish
*Layer this on top of Phase 1–4, not before — polishing unstable screens is wasted work.*

| # | Task | Repo | Status |
|---|---|---|---|
| 5.1 | Add motion (page transitions, list item entrance, button press feedback) via a lightweight animation package | app, app-user | ⬜ |
| 5.2 | Add light/dark theme support | app, app-user | ⬜ |
| 5.3 | Micro-interactions: booking confirmation success animation, offer countdown, pull-to-refresh | app-user | ⬜ |
| 5.4 | Consistent iconography and empty/loading/error state illustrations | app, app-user | ⬜ |
| 5.5 | Accessibility pass (tap target sizes, contrast, text scaling) | app, app-user | ⬜ |

---

## Phase 6 — Testing & QA

| # | Task | Repo | Status |
|---|---|---|---|
| 6.1 | Unit tests for booking conflict logic (backend) — hours, capacity, duplicate cases | cahrz-api | ⬜ |
| 6.2 | Widget tests for onboarding wizard and booking flow | app, app-user | ⬜ |
| 6.3 | Integration test: vendor creates offer → customer sees it and books → capacity blocks next booking correctly | app, app-user, cahrz-api | ⬜ |
| 6.4 | Manual QA pass on real devices (iOS + Android) for both apps | app, app-user | ⬜ |

---

## Phase 7 — Release

| # | Task | Repo | Status |
|---|---|---|---|
| 7.1 | Staged rollout (internal → beta vendors → public) | app, app-user | ⬜ |
| 7.2 | Monitor booking-conflict edge cases and crash reports post-launch | all | ⬜ |
| 7.3 | Collect vendor + customer feedback on new onboarding/booking UX, iterate | all | ⬜ |

---

## Notes
- Do Phase 0 and Phase 1 fully before Phase 5 (UI polish). Skipping straight to "make it fun" on top of 3,000-line files will make every animation change risky and slow.
- Backend conflict/geo logic (booking capacity, hours check, radius search) is already solid — the plan intentionally does not touch it beyond adding tests, only its UI/UX layer.
