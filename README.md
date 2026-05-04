# Evolve

Evolve is a web-based platform designed for physical therapy services. It improves access to rehabilitation by enabling patients to connect directly with certified therapists in a secure, digital environment.

## Table of Contents

- [About](#about)
- [Live Demo](#live-demo)
- [Getting Started](#getting-started)
- [Credentials](#credentials)
- [User Roles](#user-roles)
- [Usage Guide](#usage-guide)
- [API Docs](#api-docs)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)
- [Contact](#contact)

---

## About

Evolve is a web-based telehealth platform designed to improve access to physical therapy services through remote consultations, personalized rehabilitation support, and progress monitoring. The platform connects patients and licensed physical therapists in a secure and user-friendly environment, offering features such as appointment scheduling, virtual sessions, messaging, and treatment tracking. Developed to address accessibility challenges, especially for individuals with mobility limitations and underserved communities, Evolve aims to make physical therapy more convenient, efficient, and inclusive through digital healthcare innovation.

---

## Live Demo

**Status:** [Not Yet Deployed]

The application is currently in the final stages of development and will be hosted on **Hostinger**. Once deployed, the live link will be provided here.

---

## Getting Started

### Local Installation

To run this application on your local machine, ensure you have the following tools installed:

- PHP 8.2+
- Composer
- Node.js & npm
- MySQL / MariaDB

**Steps to install:**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/JulianIV1021/evolve-ev-charging-app.git
   cd Evolve/Evolve
   ```

2. **Install Dependencies**
   ```bash
   composer install
   npm install
   ```

3. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Update DB_DATABASE, DB_USERNAME, and DB_PASSWORD in your .env file
   ```

4. **Setup Application**
   ```bash
   php artisan key:generate
   php artisan migrate --seed
   npm run dev
   ```

5. **Start the Server**
   ```bash
   php artisan serve
   ```

### Cloud Configuration

| Setting | Detail |
|---|---|
| Hosting Provider | Hostinger |
| Status | Deployment in progress |
| Deployment Lead | Julian IV Florentino |

---

## Credentials

Use the following default credentials to access the administrative dashboard for testing:

| Role | Email | Password |
|---|---|---|
| Admin | admin@gmail.com | admin1234 |

> **Note:** Patient and Therapist accounts can be created via the registration forms on the landing page.

---

## User Roles

- **Admin** — Full system oversight, user verification, subscription management, and report generation.
- **Patient** — Search for therapists, book/manage appointments, view personal medical records, and message therapists.
- **Independent Therapist** — Manage personal practice, set availability, maintain patient EHRs, and conduct consultations.
- **Clinic Therapist** — Similar to independent therapists but managed under a clinic entity with employee management features.

---

## Usage Guide

- **Patients:** Navigate to the "Find a Therapist" section to book your first session. Use the "Messages" tab to communicate with your therapist.
- **Therapists:** Access the "Clients" dashboard to update EHRs, treatment plans, and progress notes. Ensure your "Availability" is set to receive bookings.
- **Admins:** Use the "Manage Users" section to verify new registrations and the "Reports" section to monitor platform activity.

---

## API Docs

Evolve utilizes Laravel's routing system. All endpoints require an active authenticated session (or appropriate Bearer token) and are strictly protected to ensure data privacy.

---

### `GET /api/messages/fetch`

**Description:** Retrieves the conversation history between the authenticated user and a specific recipient.

**Parameters:**
- `receiver_id` *(integer, required)* — The ID of the recipient user.

**Example Response:**
```json
[
  {
    "id": 1,
    "sender_id": 2,
    "receiver_id": 5,
    "message": "Hello, how is your progress today?",
    "type": "text",
    "created_at": "2023-10-01T10:00:00.000000Z"
  }
]
```

---

### `POST /api/messages/send`

**Description:** Sends text, files, or voice messages securely to a recipient. Triggers real-time WebSocket events via Pusher.

**Parameters:**
- `receiver_id` *(integer, required)* — The ID of the recipient.
- `message` *(string, optional)* — The text content to send.
- `file` *(file, optional)* — An attachment (e.g., pdf, image).
- `voice_message` *(file, optional)* — A recorded voice note.

**Example Response:**
```json
{
  "success": true,
  "message": {
    "id": 2,
    "sender_id": 5,
    "receiver_id": 2,
    "message": "I'm feeling much better!",
    "type": "text"
  }
}
```

---

### `POST /video/create-room`

**Description:** Initializes a secure video consultation room for telehealth sessions (powered by Daily.co). Only authorized providers can initiate calls to patients with active appointments.

**Parameters:**
- `receiver_id` *(integer, required)* — The ID of the patient to call.

**Example Response:**
```json
{
  "success": true,
  "room_name": "Evolve-5-2-1696154400",
  "room_url": "https://yourdomain.daily.co/Evolve-5-2-1696154400",
  "token": "eyJhbGciOiJIUzI1NiIsInR...",
  "redirect": "https://Evolve.com/video/room/Evolve-5-2-1696154400?token=..."
}
```

---

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Security

Evolve prioritizes data privacy. All user records are stored securely, and authentication is handled via Laravel's robust security features. If you discover any security vulnerabilities, please report them directly to the project lead for immediate resolution.

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
