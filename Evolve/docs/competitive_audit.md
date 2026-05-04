# EvolvePRO Competitive Feature Audit
*Generated: 2026-03-02 | Codebase branch: post-Phase-6 (iOS Cupertino migration complete)*

---

## Research Sources
- [EVRO Official Site](https://www.evro.ph/) — Philippines-only, DOE-recognized, GCash + credit card payment, QR-based charging, ACMobility-owned (Ayala)
- [ChargePoint App](https://www.chargepoint.com/drivers/mobile) — Global, 250k+ stations, Apple Watch, virtual waitlist, real-time push, widget support
- [PlugShare App](https://company.plugshare.com/plugshare.html) — Global crowdsourced map, community check-ins, trip planner, Pay with PlugShare, PlugScores
- [BYD Philippines EV App Guide](https://bydcarsphilippines.com/blog/top-ev-apps-philippines)
- [EV Charging App Must-Have Features 2024](https://stormotion.io/blog/how-to-make-an-ev-charging-station-app/)

---

## 1. Feature Comparison Table

| Feature | EVRO | ChargePoint | PlugShare | EvolvePRO (us) | Gap? |
|---|---|---|---|---|---|
| Map-based station discovery | ✅ | ✅ | ✅ | ✅ (StationsMapScreen + Firestore markers) | 🟢 Done |
| Real-time availability | ✅ | ✅ | ✅ | ✅ (Firestore snapshots on charger docs) | 🟢 Done |
| Station filters | ✅ | ✅ | ✅ | ✅ (FilterSheet: AC/DC, connector type, power, price, compatibility) | ⭐ We do it better (compatibility-aware filter) |
| Turn-by-turn navigation | ✅ | ✅ | ❌ | ✅ (TurnByTurnScreen + Google Maps Directions API) | 🟢 Done |
| Green/eco route option | ✅ | ❌ | ❌ | ✅ (GreenRoutingService: CO₂ savings, SoC buffer, efficiency rating) | ⭐ We do it better |
| QR scan to charge | ✅ | ❌ | ❌ | ✅ (ScanQrScreen + ScanOrEnterScreen + manual code entry) | ⭐ We do it better (manual fallback too) |
| Remote start charging | ✅ | ✅ | ❌ | ✅ (ConfirmStartScreen → Firestore session FSM) | 🟢 Done |
| Real-time session monitoring | ✅ | ✅ | ❌ | ✅ (ChargingScreen streams Firestore charger doc) | 🟢 Done |
| Session timer display | ✅ | ✅ | ❌ | ✅ (elapsed timer in ChargingScreen) | 🟢 Done |
| Energy delivered display | ✅ | ✅ | ❌ | ✅ (energyKwh shown in ChargingScreen + SessionDetailScreen) | 🟢 Done |
| Cost display in-session | ✅ | ✅ | ❌ | 🟡 (totalCost shown, but live cost calculation depends on Firestore) | 🟡 Partial |
| Idle fee alerts | ✅ | ✅ | ❌ | ✅ (idle_fee FSM state + NotificationService push alerts) | 🟢 Done |
| Stop charging in-app | ✅ | ✅ | ❌ | ✅ (red stop button in ChargingScreen → Firestore transaction) | 🟢 Done |
| Session history | ✅ | ✅ | ✅ | ✅ (ActivityScreen + SessionDetailScreen with full cost breakdown) | 🟢 Done |
| Digital receipt | ✅ | ✅ | ❌ | 🟡 (SessionDetailScreen shows cost breakdown but no PDF/email export) | 🟡 Partial |
| Payment in-app | ✅ (GCash, card) | ✅ | ✅ | ❌ (no payment integration — charging is free or billed separately) | 🔴 Missing |
| Saved payment methods | ✅ | ✅ | ❌ | ❌ | 🔴 Missing |
| Reserve/hold a charger | ✅ | ✅ | ❌ | ✅ (ReservationService with Firestore + client-side expiry timer) | 🟢 Done |
| Push notifications | ✅ | ✅ | ✅ | ✅ (NotificationService: FCM + local, reservation expiring, charger available) | 🟢 Done |
| Station reviews/ratings | ❌ | ✅ | ✅ | ❌ | 🔴 Missing |
| Check-in / community | ❌ | ❌ | ✅ | ❌ | 🔴 Missing (P2) |
| EV vehicle profile | ✅ | ✅ | ✅ | ✅ (VehicleProfileScreen: make/model, battery kWh, SoC%, connectors, max kW) | 🟢 Done |
| Connector compatibility filter | ✅ | ✅ | ✅ | ✅ (filter uses EVProfile.connectors to auto-filter stations) | ⭐ We do it better (auto-applied from profile) |
| Favorites / saved stations | ✅ | ✅ | ✅ | ❌ | 🔴 Missing |
| Offline / cached map | ❌ | ✅ | ✅ | 🟡 (OfflineBanner shows degraded state but no offline map tiles cached) | 🟡 Partial |
| Multi-language support | ✅ | ✅ | ✅ | ❌ (English only) | 🔴 Missing (P2) |
| Dark mode | ✅ | ✅ | ✅ | 🟡 (CupertinoThemeData.dark exists in app_theme.dart but not user-selectable) | 🟡 Partial |
| Apple Sign In | ✅ | ✅ | ❌ | ❌ (email/password only) | 🔴 Missing |
| Google Sign In | ✅ | ✅ | ✅ | ❌ (email/password only) | 🔴 Missing |
| Admin approval gate | ❌ | ❌ | ❌ | ✅ (MainShell streams Firestore approved field; blocks unapproved users) | ⭐ Unique to us |
| Kiosk/station interop | ❌ | ❌ | ❌ | ✅ (QR kiosk → mobile app session FSM; kiosk resets charger docs) | ⭐ Unique to us |
| Route options comparison | ❌ | ❌ | ❌ | ✅ (RouteOptionsScreen compares fastest/shortest/greenest with SoC estimate) | ⭐ Unique to us |
| Search tab | ✅ | ✅ | ✅ | 🟡 (SearchPlaceholderScreen — UI stub only, no search logic) | 🟡 Partial |
| Trip planner | ❌ | ✅ | ✅ | ❌ | 🔴 Missing |

---

## 2. UI/UX Comparison

| Dimension | EVRO | ChargePoint | EvolvePRO (us) | Our Status |
|---|---|---|---|---|
| Design system | iOS-native Cupertino | Material + custom hybrid | Full Cupertino (0 Material widgets) | ⭐ We are more native than EVRO |
| Map marker design | Custom colored pins by status | Colored pin clusters | Google Maps default pins (no custom markers) | 🔴 Needs custom markers |
| Station detail sheet | Modal bottom drawer | Full-screen push | Modal bottom drawer (StationDetailSheetContent) | 🟢 Matches best practice |
| Charging screen style | Dark ring progress, ambient glow | Light card layout | Light card + custom `_RingPainter` arc progress | 🟢 Done |
| Tab bar style | Standard 4-tab | Standard 5-tab | Floating center CTA (Scan) with amber glow | ⭐ Better than both |
| Onboarding flow | 3-screen illustrated splash | 5-step account setup | Splash → Login/Signup (no illustrated onboarding) | 🔴 Missing onboarding |
| Empty states | Illustrated SVG art | Text only | Icon + text (no illustration) | 🟡 Partial |
| Loading states | Skeleton screens | Spinner | `CupertinoActivityIndicator` (spinner) | 🟡 Could improve |
| Error handling | Inline banner + toast | Alert dialog | Inline text (no retry button in most screens) | 🟡 Partial |
| Haptic feedback | Full (on every tap) | Minimal | ✅ AppHaptics used on filter/buttons (mediumImpact, selectionClick) | 🟢 Done |
| Station name display | Visible on map | Visible on map | Not shown on map markers (stationId only in Activity) | 🔴 Map UX gap |
| Price display on map | ✅ | ✅ | ❌ (price only shown in filter and session detail) | 🔴 Missing on map |

---

## 3. Our Unique Advantages

Things we have that **all** competitors lack:

1. **Admin Approval Gate** — `MainShell` blocks unapproved users at the Firestore stream level. Competitors rely on network-level account verification only. Ours is real-time and reversible without an app update.

2. **QR Kiosk ↔ Mobile Session FSM Interop** — The kiosk hardware writes to Firestore charger docs; our app reads that in real time and drives the entire session state machine (`pending_start → active → complete → idle_fee → ended`). No competitor has a first-party kiosk integration on mobile.

3. **Green Route Selection with SoC Buffer** — `GreenRoutingService` scores routes by energy efficiency, CO₂ grams saved, and arrival SoC with a configurable minimum buffer. No other Philippine EV app does this. ChargePoint does trip planning but not EV-SoC-aware green routing.

4. **Floating Center-Scan Tab Bar** — The `_EvroTabBar` design with the 64×64 amber floating Scan CTA is visually distinctive and prioritizes the core charging action above all else. Neither EVRO nor ChargePoint uses this pattern.

5. **Connector Compatibility Auto-Filter** — When a vehicle profile is saved, the station filter automatically defaults `compatibleOnly: true`, pre-filtering the map to only show stations the user's car can actually charge at. EVRO requires manual connector selection.

6. **Manual Code Entry Fallback** — `EnterChargerCodeScreen` lets users type the charger code if QR scanning fails. Neither EVRO nor ChargePoint documents this fallback path.

---

## 4. Critical Gaps — Features We Are Missing

### P0 — Kills User Trust If Missing

| # | Feature | Why it matters |
|---|---|---|
| P0-1 | **In-app payment (GCash / card)** | Users cannot pay without leaving the app. EVRO's #1 advertised feature. Blocking for commercial launch. |
| P0-2 | **Google Sign In / Apple Sign In** | Email-only auth creates high drop-off. Apple requires Apple Sign In if any social login is offered (App Store rule). |
| P0-3 | **Custom map markers by availability** | Users cannot distinguish available vs. occupied chargers on the map at a glance. Core UX of every competing app. |
| P0-4 | **Station name on map + detail** | The app shows `stationId` (e.g. `EVOLVE-S1`) instead of a human-readable name in Activity cards. Confusing. |

### P1 — Significantly Hurts Retention

| # | Feature | Why it matters |
|---|---|---|
| P1-1 | **Favorites / Saved Stations** | Users revisit the same 2–3 chargers 80% of the time. PlugShare and ChargePoint both have this. Zero friction to reuse. |
| P1-2 | **Station search by name/address** | The Search tab is a placeholder. Users cannot find a specific mall or address. EVRO and ChargePoint both have full search. |
| P1-3 | **Onboarding flow (illustrated)** | Cold installs hit Login immediately. No explanation of what the app does, what QR charging is, or how to register. High bounce. |
| P1-4 | **Station reviews / ratings** | Users want social proof before driving to a station. ChargePoint and PlugShare both use ratings as a retention loop. |
| P1-5 | **Dark mode toggle (user-settable)** | Dark theme exists in `app_theme.dart` but is hardcoded to light. iOS users expect system appearance to be respected. |

### P2 — Nice to Have

| # | Feature | Why it matters |
|---|---|---|
| P2-1 | Station check-in / community (PlugShare-style) | Social retention — not critical for B2B/fleet use case |
| P2-2 | Multi-language (Filipino/Tagalog) | Broadens PH market but English is standard for PH EV owners |
| P2-3 | Offline cached map tiles | Helpful in areas with poor signal; complex to implement correctly |
| P2-4 | Trip planner (multi-stop charging) | ABRP already does this well; not core to urban PH charging use case |
| P2-5 | PDF/email receipt export | SessionDetailScreen shows data but no export |
| P2-6 | Price visible on map markers | Nice UX refinement |

---

## 5. Quick Wins — Under 2 Days

| Feature | File(s) to touch | Complexity | Why it matters |
|---|---|---|---|
| **Favorites (saved stations)** | Add `favorites` array to Firestore `users/{uid}` doc. New `favorites_provider.dart`. Add heart icon to `StationDetailSheetContent` | **Low** | Highest user-retention feature. 1 Firestore field + 1 icon button. |
| **Station name on map markers** | `StationsMapScreen` — add `BitmapDescriptor` custom marker with station name label | **Low** | Currently all markers look identical. Name text on marker = immediately scannable. |
| **System dark mode (auto)** | `main.dart` — read `MediaQuery.platformBrightnessOf(context)` and pass to `CupertinoThemeData(brightness:)` | **Low** | `cupertinoDark` theme already exists. One-line change to respect OS setting. |
| **Station name in Activity cards** | `ActivityScreen._SessionCard` — replace `'Station: $stationId'` with a Firestore lookup for `stations/{stationId}.name` | **Low** | Users see raw IDs like `EVOLVE-S1` instead of `SM Aura Charging Hub` |
| **Search tab (station name search)** | Replace `SearchPlaceholderScreen` with real search using `stationFilterProvider` + text query against loaded station list | **Medium** | Entire Search tab is a stub. Uses data already in memory (stations provider). |
| **Retry button on error states** | `ActivityScreen._ErrorState`, `RouteOptionsScreen._ErrorState` — add a `CupertinoButton('Try again')` | **Low** | Currently users must background/foreground the app to retry. 5 minutes of work. |
| **Onboarding screen (3 slides)** | New `lib/screens/onboarding/onboarding_screen.dart`. Router shows it once (SharedPreferences flag). | **Medium** | Reduces cold-install drop-off significantly. 3 static slides explaining QR charging. |
| **System appearance dark mode** | `EvolveProApp` → wrap `CupertinoApp.router` with `MediaQuery` check for `Brightness.dark` → swap theme | **Low** | Already have `cupertinoDark` theme. Zero design work needed. |

---

## 6. Recommended Next Sprint (Top 5 Priorities)

| Priority | Feature | Reason |
|---|---|---|
| **#1** | Custom map markers (available=green, occupied=red, offline=grey) | P0 UX gap — the map is the app's primary interface and currently all stations look identical |
| **#2** | Favorites / saved stations | Highest retention feature, lowest implementation effort — 1 Firestore field, 1 icon, 1 provider |
| **#3** | System dark mode (auto, respects iOS setting) | Theme already built. Zero design cost. Removing hardcoded light mode = iOS App Store compliance |
| **#4** | Search tab — station name/address search | Second tab is entirely a placeholder. Users tap it expecting search and get nothing. |
| **#5** | Onboarding flow (3 illustrated slides) | Every first install hits Login with zero context. 3 static Cupertino slides fix cold-install bounce rate. |

---

## Answers

### 1. Single most critical gap right now
**Custom map markers by availability status.** The map is the first thing users see when they open the app, and every single charger pin looks identical — users cannot tell at a glance which stations are free, occupied, or offline. This is the core UX of every competing app (EVRO, ChargePoint, PlugShare all have color-coded availability pins). It can be fixed with `BitmapDescriptor.fromAssetImage()` or a canvas-drawn custom marker.

### 2. Single quickest win this week
**Favorites / saved stations.** Add a heart icon to `StationDetailSheetContent`, store a `List<String>` of station IDs in `users/{uid}.favorites` in Firestore, and create a `favoritesProvider` that streams it. Total estimated work: ~4 hours. Impact: users can save their home/work charger and open it in one tap — the most common real-world use pattern.

### 3. One thing we do better than EVRO right now
**Green route selection with SoC awareness.** EVRO offers navigation to a station, but we compute three route options (fastest / shortest / greenest), score each by energy efficiency, estimate the arrival SoC, enforce a minimum SoC buffer to avoid arriving dead, and display CO₂ grams saved per route. EVRO (and ChargePoint) have no equivalent. This is a genuine product differentiator for range-anxious EV drivers.
