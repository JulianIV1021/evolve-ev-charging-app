# Evolve

Evolve is a mobile application for Electric Vehicle (EV) charging. It allows EV drivers to locate nearby charging stations, start and monitor charging sessions in real time, and track their charging history — all from their smartphone.

## Table of Contents

- [About](#about)
- [Live Demo](#live-demo)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [User Roles](#user-roles)
- [Usage Guide](#usage-guide)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)
- [Contact](#contact)

---

## Live Demo

▶️ [Watch the Evolve App Demo](https://github.com/JulianIV1021/evolve-ev-charging-app/blob/main/Evolve/assets/Evolve%20Live%20demo.mp4)

> Click the link above to watch a full walkthrough of the Evolve EV charging app — including station discovery, QR code scanning, live charging session monitoring, and activity history.

---

## About

Evolve is a Flutter-based mobile application built for EV drivers who need a fast, reliable way to find and use EV charging stations. The app connects to a Firebase backend and displays real-time charger availability on an interactive Google Maps interface. Users can start a session by scanning a QR code or entering a charger ID manually, monitor their charging progress live, and review their complete charging history with energy consumed and cost breakdown.

Designed with an iOS-style Cupertino UI, Evolve delivers a clean and intuitive experience for everyday EV charging needs.

---

## Features

- 🗺️ **Interactive Map** — View nearby EvolvePRO charging stations on Google Maps with real-time availability status (Available, Busy, Offline)
- 🔍 **Station Search & Filters** — Search stations by name and filter by availability, charger type, and more
- 📷 **QR Code Scanning** — Scan the QR code on any EvolvePRO charger to instantly start a session
- ⌨️ **Manual Charger Entry** — Enter a Charger ID manually if QR scanning is not available
- ⚡ **Live Charging Session** — Monitor your session in real time with an animated progress ring showing time remaining, energy delivered (kWh), and running cost (₱)
- 🔔 **Smart Notifications** — Receive alerts when charging completes, when a grace period starts, and when idle fees begin accumulating
- 📋 **Activity History** — Browse your full charging session history with energy and cost summaries per session
- 🚗 **EV Vehicle Profile** — Set up your vehicle make, model, and battery capacity for personalized range estimates
- 🔋 **Battery State of Charge** — See your current EV battery percentage and estimated remaining range on the home screen
- 🔐 **Authentication** — Secure login and registration with email/password or Google Sign-In via Firebase Auth
- 📡 **Offline Detection** — The app detects when the device goes offline and displays a banner to warn the user

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Firebase (Firestore, Auth, Messaging, Analytics, Crashlytics) |
| Maps | Google Maps Flutter |
| Location | Geolocator |
| State Management | Riverpod |
| Navigation | GoRouter |
| Notifications | Flutter Local Notifications |
| HTTP Client | Dio |
| Authentication | Firebase Auth + Google Sign-In |
| UI Style | Cupertino (iOS-style) |

---

## Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.9.2`)
- Android Studio or VS Code with Flutter extension
- A physical Android or iOS device, or an emulator

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/JulianIV1021/evolve-ev-charging-app.git
   cd evolve-ev-charging-app/Evolve
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**

   The app requires a Firebase project. Place your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) file in the appropriate platform directory:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

   > ⚠️ These files are excluded from the repository for security. Contact the project lead to obtain them.

4. **Run the App**
   ```bash
   flutter run
   ```

---

## User Roles

- **EV Driver (User)** — Registers an account, sets up a vehicle profile, finds stations on the map, scans or enters a charger ID, monitors live sessions, and views charging history.

> Note: Station and charger management is handled on the backend (Firestore). The mobile app is the driver-facing client only.

---

## Usage Guide

### Starting a Charging Session
1. Open the app and log in
2. On the **Home** screen, tap **Scan QR Code** and point your camera at the QR code on the charger
3. Alternatively, tap **Enter Charger ID manually** and type in the charger code
4. Confirm the charger details on the next screen and start the session

### Monitoring Your Session
- The **Charging** screen shows a live progress ring with minutes remaining, energy delivered in kWh, and your running cost in ₱
- You will receive a push notification when charging is complete and when the grace period or idle fee begins
- Tap **Stop Charging** at any time to end the session early

### Finding a Station
- Go to the **Stations** tab to open the Google Maps view
- Tap any marker to see station details (availability, chargers, location)
- Use the **Search** tab to find a station by name
- Use the **Filter** button to narrow results by status or charger type

### Viewing History
- Go to the **Activity** tab to see all your past charging sessions
- Each card shows the station name, date, energy used (kWh), and total cost (₱)
- Tap any session card for a full breakdown

---

## Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Security

Evolve uses Firebase Authentication to handle all user sessions securely. Firestore security rules restrict data access to authenticated users only. Sensitive configuration files (`google-services.json`, `GoogleService-Info.plist`, API keys) are excluded from version control and should never be committed to the repository.

If you discover a security vulnerability, please report it directly to the project lead for immediate resolution.

---

## License

Evolve is an academic capstone project developed for research and educational purposes. This repository and its contents are provided for demonstration and evaluation only. Commercial use, redistribution, or reuse of the system, source code, or documentation without written permission from the project proponents is not permitted.

---

## Contact

| Role | Name |
|---|---|
| Project Lead | Soria, Azylei |
| Lead Developer | Florentino, Julian IV |
| GitHub | [JulianIV1021](https://github.com/JulianIV1021) |
