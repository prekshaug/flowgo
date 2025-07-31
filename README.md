# 🚀 FlowGo – Mood-Based Smart Travel Planner

FlowGo is a wellness + productivity mobile app built with Flutter that helps users create and schedule smart travel plans optimized by **mood**, **location**, and **real-time traffic**. It integrates with **Google Maps Platform APIs** to suggest the best departure time and route so users always arrive calm, focused, and on time.

---

## ✨ Features

- 🧠 **Mood-Based Route Suggestions** – Choose your mood (calm, focus, energized) to get the ideal travel route using traffic data and smart filters.
- 📍 **Current Location & Autocomplete** – Auto-detects your location and offers destination suggestions using Google Places API.
- 🗓️ **Plan Your Day** – Schedule your task/appointment by setting destination, mood, and time.
- ⏰ **Smart Time Suggestions** – Suggests the best time to leave based on ETA calculated with real-time traffic.
- 🗺️ **Route Preview with Google Maps** – Visual map with polylines for your route and travel duration estimate.
- 🔔 **Local Notifications** – Option to enable reminders 5 minutes before travel.
- 📄 **Task List** – View all your plans from the "FlowGo Planner" screen.

---

## 🛠️ Built With

- **Flutter** – Frontend and mobile framework
- **Dart** – Language used in Flutter
- **Google Maps Directions API**
- **Google Maps Places API**
- **Google Maps Geocoding API**
- **Flutter Local Notifications**
- **Geolocator** – For fetching current location
- **flutter_polyline_points** – For decoding route paths

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android Studio or VS Code
- A valid **Google Maps API Key**
- Android emulator or physical Android device

---

### Installation

```bash
git clone https://github.com/yourusername/flowgo.git
cd flowgo
flutter pub get
flutter run
