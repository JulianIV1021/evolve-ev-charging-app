# EvolvePRO to EVRO-Style App Brief (For Claude)

Use this as the source of truth for planning and implementation.

## 1) Product Goal
Build **EvolvePRO** into an EV charging companion that feels like **Waze for EV drivers**:
- Find the best charging station fast
- Navigate there with live, energy-aware routing
- Start/monitor/stop charging in-app
- Pay and track charging history

## 2) What We Already Have (Current App)
Tech stack:
- Flutter mobile app
- Firebase Auth (email/password)
- Cloud Firestore (users, stations/chargers, sessions)
- QR scanning for charger start flow
- Local notifications

Implemented user flow:
- Login/Register on one screen
- Auto-create Firestore user profile on first auth
- Admin approval gate (`users/{uid}.approved == true` required)
- Home screen with Start Charging entry
- Choose QR scan or manual charger code entry
- Confirm charging duration
- Create `sessions` record with `pending_start`
- Charging screen with:
  - real-time session status updates
  - timer ring and elapsed/remaining time
  - energy, cost, idle fee display
  - notifications for `complete` and `idle_fee`
  - user can end session (`status = ended`)

Important current architecture behavior:
- Kiosk/station side controls charger state transitions
- Mobile app requests/monitors session and ends session, but does not directly reset charger document

## 3) EVRO-Level Features We Must Add
### P0 (Must Have)
- Dedicated polished **Login** and **Sign Up** pages (plus password reset)
- Bottom navigation app structure:
  - Stations
  - Search
  - Scan/Charge
  - Activity
  - Profile
- **Map-based station discovery** with live markers
- Station filters:
  - Charger type (AC/DC)
  - Availability (available/busy/offline)
  - Connector compatibility
  - Power range and price range
- Station detail sheet:
  - distance, availability count, connector list, pricing, amenities
  - actions: Navigate, Hold Slot, Charge Now
- **Live navigation to selected station**
- **Green route routing** (energy-aware path selection)
- Real-time station status updates and auto refresh
- Session history and receipts
- Payment method and checkout flow

### P1 (Should Have)
- Predictive availability / queue estimate for stations
- Reserve/hold window with auto-release
- Favorites and recent stations
- Push notifications (reservation expiring, charger available, session finished)
- In-app support/report issue

### P2 (Nice to Have)
- Smart recommendations ("best station on your route")
- Fleet or business mode
- Rewards/loyalty and promo handling

## 4) Live Navigation + Green Routing Requirements (Critical)
Routing must optimize for EV constraints, not just shortest distance.

Inputs:
- Current location, destination (or chosen station)
- Vehicle profile: battery capacity, current SoC, connector support, max charging power
- Live traffic, road speed, elevation (if available)
- Station live status, price, and queue estimate

Outputs:
- Best route options with:
  - ETA
  - predicted arrival SoC
  - total energy use estimate
  - charging stop recommendation(s) if needed
  - route score: fastest vs cheapest vs greenest

Behavior:
- Auto-reroute if selected station becomes busy/offline/full
- Auto-reroute on major traffic changes
- Keep safety buffer (for example minimum 10-15% arrival SoC)
- Show "Green Route" badge for lowest estimated consumption/CO2 route

## 5) UX Screens We Need
- Splash / onboarding
- Login
- Sign Up
- Forgot Password
- Stations map (main)
- Station details modal/page
- Route options page (Fastest / Cheapest / Greenest)
- Turn-by-turn navigation screen
- Scan QR / enter charger code
- Confirm charge start
- Charging in progress
- Charging complete summary
- Activity (session list + details + receipts)
- Profile (vehicle, connectors, payment methods, app settings)

## 6) Backend/Data Requirements
Collections to keep or expand:
- `users`: profile, approval, vehicles, connector preferences
- `stations`: location, amenities, pricing metadata
- `stations/{stationId}/chargers`: connector, power, status, queue
- `sessions`: lifecycle, meter values, billing, timestamps
- `reservations`: hold windows and expiry
- `routes` (optional cache): last computed route alternatives

Add services:
- Routing service integration (map + traffic + directions API)
- EV consumption estimator service
- Reservation/queue manager
- Billing/payment orchestration
- Notification events processor

## 7) Non-Functional Requirements
- Real-time updates under 2-3 seconds for station/session status
- Fail-safe behavior for poor network (cached last known station data)
- Secure payment and user data handling
- Error states for unavailable station, payment failure, session timeout
- Crash and analytics instrumentation

## 8) Definition of Done (MVP)
MVP is complete only when a user can:
1. Sign up, log in, and set EV profile
2. See nearby stations on a map with live availability
3. Filter by compatibility and charger type
4. Select a station and get live navigation
5. See at least one Green Route option
6. Start charging (QR or remote), monitor session, and stop session
7. Pay and view receipt in Activity

## 9) Implementation Priority
1. UX foundation: auth split pages + bottom navigation + map shell
2. Station real-time map + filter + detail sheet
3. Live navigation integration
4. Green routing and reroute logic
5. Reservation + payment + activity polish

## 10) Build Constraint
Preserve current working charging flow and Firestore session lifecycle, then layer map/navigation/routing modules on top without breaking kiosk interoperability.
