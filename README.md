# Kashat | كشتات ⛺️✨

**Kashat** is your ultimate guide to camping in Saudi Arabia. Discover the best camping spots, check real-time weather, and connect with a community of outdoor enthusiasts.

> **Note:** The "Rental Marketplace" feature is currently in development and marked as "Coming Soon" in the app.

## Features 🚀

### 🗺️ Explore & Discover
-   **Interactive Map**: Find hidden gems, valleys, dunes, and beaches near you.
-   **Spot Details**: Get viewing coordinates, terrain info, and user ratings.
-   **Real-Time Weather**: Integrated with **Apple WeatherKit** to show temperature, wind speed, and precipitation chance for every spot.
-   **External Navigation**: One-tap directions via Google Maps or Waze.

### 👥 Community & Social
-   **Reviews & Photos**: Share your experience and upload photos of your camp.
-   **Admin Badge**: Verified admins have a special shield badge 🛡️.
-   **Favorites**: Save your top spots for later.

### 👤 User Profile
-   **Secure Login**: OTP-based authentication via Phone Number.
-   **Wallet**: Manage your balance (points/credit system).
-   **Bilingual**: Full support for **Arabic (RTL)** and English.

## Tech Stack 🛠️

-   **Language**: Swift 5
-   **Framework**: SwiftUI
-   **Backend**: Firebase (Firestore, Auth, Storage, Functions, Remote Config, Analytics)
-   **APIs**: Apple WeatherKit
-   **Architecture**: MVVM + Singleton Managers

## Setup Instructions 📱

1.  **Clone the repo**:
    ```bash
    git clone https://github.com/your-repo/kashat.git
    cd Kashat
    ```
2.  **Install Dependencies**:
    ```bash
    # Ensure you have CocoaPods installed
    pod install
    ```
3.  **Firebase Config**:
    -   Add your `GoogleService-Info.plist` to the `Kashat/` directory.
    -   Enable Authentication (Phone), Firestore, and Storage in your Firebase Console.
4.  **WeatherKit**:
    -   Ensure "WeatherKit" capability is enabled in your Apple Developer Account and Xcode project.
5.  **Run**:
    -   Open `Kashat.xcworkspace`.
    -   Select a simulator or device and hit Run (Cmd+R).

## Privacy & Legal ⚖️

-   [Privacy Policy](https://your-privacy-policy-url.com) (See `privacy_policy.md`)
-   [Terms of Service](https://your-terms-url.com)

---

Developed with ❤️ for the KSA Camping Community.
