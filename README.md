# Lands Auctions Flutter Project

Welcome to **Lands Auctions**, a powerful Flutter application designed to modernize land trading and auctioning. This app connects traders, buyers, and administrators in a real-time, efficient platform for submitting lands, placing bids, and managing auctions.

---

## About the Application

**Lands Auctions** streamlines the land auction process with a robust feature set and dual-database architecture.

### Key Features
- **Land Submission**: Traders submit land details, automatically creating auctions.
- **Real-Time Bidding**: Live bid updates via Socket.IO integration.
- **Admin Management**: Edit lands, auctions, and upload JSON data for polygons.
- **Notifications**: Real-time alerts for bids and auction endings.
- **Dual Storage**: Firebase Firestore for primary data, Railway API as a backup.

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore, Railway API
- **Real-Time**: Socket.IO (`socket_io_client: ^2.0.3+1`)
- **Notifications**: Flutter Local Notifications
- **Key Packages**: `http`, `cloud_firestore`, `file_picker`, `url_launcher`

### Application Flow
1. **OTP Verification**: Users verify their phone number via Twilio SMS (`OTPVerificationPage`).
2. **Land Auction Page**: Displays land details, bids, and a countdown timer (`LandAuctionPage`).
3. **Admin Search**: Combines Firebase and Railway data for land/auction management (`LandsAdminAuctionsSearch`).

---

## Getting Started

Set up the project with these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/aliabuhatab/lands_auctions_flutter_project.git
   cd lands_auctions_flutter_project
