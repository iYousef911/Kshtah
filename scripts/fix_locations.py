import firebase_admin
from firebase_admin import credentials, firestore
import os

SERVICE_ACCOUNT_KEY_PATH = "scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def fix_locations():
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        print(f"Key not found at {SERVICE_ACCOUNT_KEY_PATH}")
        return

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    spots_ref = db.collection('spots')

    # 1. Fix Wadi Namar (وادي نمار)
    # Coordinates: 24.5865, 46.6934 (Wadi Namar Dam)
    namar_updates = {
        "location": "الرياض",
        "latitude": 24.5865,
        "longitude": 46.6934,
        "type": "وادي" # Ensure type is set
    }
    
    # Query for Wadi Namar
    docs = list(spots_ref.where("name", "==", "وادي نمار").stream())
    if docs:
        for doc in docs:
            print(f"Updating Wadi Namar ({doc.id})...")
            doc.reference.update(namar_updates)
    else:
        print("Wadi Namar not found. Creating it...")
        # Create new if not exists
        import uuid
        new_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, "وادي نمار")).upper()
        spots_ref.document(new_id).set({
            "name": "وادي نمار",
            "rating": 4.8,
            "numberOfRatings": 150,
            "imageURL": "https://loremflickr.com/800/600/saudi,wadi,namar?random=1",
            **namar_updates
        }, merge=True)

    # 2. Fix Wadi Hanifa (وادي حنيفة) and the typo Wadi Hatifa (وادي حتيفة)
    # Coordinates: 24.6468, 46.5926 (Wadi Hanifa Park)
    hanifa_updates = {
        "location": "الرياض",
        "latitude": 24.6468,
        "longitude": 46.5926,
        "type": "وادي",
        "name": "وادي حنيفة" # Corret name
    }

    # Search for TYPO "وادي حتيفة"
    typo_docs = list(spots_ref.where("name", "==", "وادي حتيفة").stream())
    for doc in typo_docs:
        print(f"Found Typo 'وادي حتيفة' ({doc.id}). Updating to 'وادي حنيفة'...")
        doc.reference.update(hanifa_updates)

    # Search for CORRECT "وادي حنيفة" to ensure location is updated
    hanifa_docs = list(spots_ref.where("name", "==", "وادي حنيفة").stream())
    for doc in hanifa_docs:
        print(f"Updating Wadi Hanifa ({doc.id}) location...")
        doc.reference.update(hanifa_updates)

    print("✅ Locations updated successfully.")

if __name__ == "__main__":
    fix_locations()
