import firebase_admin
from firebase_admin import credentials, firestore
import os

SERVICE_ACCOUNT_KEY_PATH = "scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def list_wadi_spots():
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        print("Key not found")
        return

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    
    # Get all spots
    docs = db.collection('spots').stream()
    
    print(f"{'ID':<35} | {'Name':<20} | {'Lat':<10} | {'Lon':<10}")
    print("-" * 85)
    
    for doc in docs:
        data = doc.to_dict()
        name = data.get('name', 'Unknown')
        if "وادي" in name or "Wadi" in name:
            lat = data.get('latitude', 0)
            lon = data.get('longitude', 0)
            print(f"{doc.id:<35} | {name:<20} | {lat:<10} | {lon:<10}")

if __name__ == "__main__":
    list_wadi_spots()
