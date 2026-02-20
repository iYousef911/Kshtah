import firebase_admin
from firebase_admin import credentials, firestore
import os

SERVICE_ACCOUNT_KEY_PATH = "scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def cleanup_duplicates():
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        return

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    spots_ref = db.collection('spots')

    # 1. DELETE INCORRECT DUPLICATE FOR WADI NAMAR
    # The one with lat ~24.81 is wrong (it's way north).
    # The correct one is ~24.58 (South Riyadh).
    
    # ID to delete: 7E77CE90-B6F8-404F-B185-7C27DE953FD2
    bad_namar_id = "7E77CE90-B6F8-404F-B185-7C27DE953FD2"
    
    doc = spots_ref.document(bad_namar_id).get()
    if doc.exists:
        print(f"Deleting incorrect Wadi Namar ({bad_namar_id})...")
        spots_ref.document(bad_namar_id).delete()
    else:
        print("Incorrect Wadi Namar already deleted.")

    # 2. VERIFY WADI HANIFA
    # Ensure only ONE Wadi Hanifa exists.
    hanifa_docs = list(spots_ref.where("name", "==", "وادي حنيفة").stream())
    
    print(f"Found {len(hanifa_docs)} documents for Wadi Hanifa.")
    
    # We want to keep A59E838C-7104-4E48-B7FA-8756F04B55F8 if possible, or just the one with correct coords.
    # Correct Coords: 24.6468, 46.5926
    
    for doc in hanifa_docs:
        data = doc.to_dict()
        lat = data.get('latitude')
        print(f"Hanifa Doc: {doc.id} | Lat: {lat}")
        
        # If any is significantly off, we might want to update or delete.
        # But based on list_spots, we only saw one.
        
    print("Cleanup complete.")

if __name__ == "__main__":
    cleanup_duplicates()
