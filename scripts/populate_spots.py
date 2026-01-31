import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import json
import os
import sys

# Configuration
SERVICE_ACCOUNT_KEY_PATH = "kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json" # Auto-detected key
DEFAULT_DATA_FILE_PATH = "saudi_spots_data_v2.json" # Default

def initialize_firebase():
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        print(f"Error: Service account key not found at {SERVICE_ACCOUNT_KEY_PATH}")
        print("Please download your service account key from Firebase Console > Project Settings > Service Accounts")
        return None

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    return firestore.client()

def upload_spots(db, data_file_path):
    if not os.path.exists(data_file_path):
        print(f"Error: Data file not found at {data_file_path}")
        return

    print(f"Reading data from: {data_file_path}")
    with open(data_file_path, 'r', encoding='utf-8') as f:
        spots_data = json.load(f)

    print(f"Found {len(spots_data)} spots to upload...")

    collection_ref = db.collection('spots')
    
    count = 0
    for spot in spots_data:
        # Check if spot with same name already exists
        query = collection_ref.where("name", "==", spot["name"]).limit(1).stream()
        existing_doc = next(query, None)
        
        if existing_doc:
            doc_ref = existing_doc.reference
            print(f"Updating existing spot: {spot['name']}")
        else:
            doc_ref = collection_ref.document()
            print(f"Creating new spot: {spot['name']}")
        
        # Prepare data with types matching Firestore schema
        data = {
            "name": spot["name"],
            "location": spot["location"],
            "type": spot["type"],
            "rating": float(spot["rating"]),
            "numberOfRatings": int(spot["numberOfRatings"]),
            "latitude": float(spot["latitude"]),
            "longitude": float(spot["longitude"]),  # Ensure these are simple floats as seen in model
            "imageURL": spot["imageURL"]
        }
        
        doc_ref.set(data, merge=True)
        count += 1

    print(f"Successfully uploaded {count} spots!")

if __name__ == "__main__":
    data_file = DEFAULT_DATA_FILE_PATH
    if len(sys.argv) > 1:
        data_file = sys.argv[1]

    db = initialize_firebase()
    if db:
        upload_spots(db, data_file)
