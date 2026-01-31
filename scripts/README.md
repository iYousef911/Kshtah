# Saudi Spots Script Instructions

This folder contains a Python script to populate your Firestore `spots` collection with popular locations in Saudi Arabia.

## Prerequisites

1. **Python 3**: Ensure you have Python installed.
2. **Firebase Admin SDK**: Install the library using pip:
   ```bash
   pip install firebase-admin
   ```

## Setup

1. **Get Service Account Key**:
   - Go to [Firebase Console](https://console.firebase.google.com/) > Project Settings > Service Accounts.
   - Click "Generate new private key".
   - Save the JSON file as `serviceAccountKey.json` inside this `scripts/` folder.

2. **(Optional) Edit Data**:
   - The file `saudi_spots_data.json` contains the list of spots. You can add or modify them as needed.

## Run

Run the script from terminal:

```bash
cd scripts
python3 populate_spots.py
```

The script will iterate through the JSON list and add each spot as a new document in the `spots` collection.
