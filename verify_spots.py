import firebase_admin
from firebase_admin import credentials, firestore
import os

SERVICE_ACCOUNT_KEY_PATH = "scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def verify():
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        print("Key not found")
        return

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # List of spots we added/updated
    spot_names = [
        "حافة العالم", "وادي الديسة", "جبال الفيل (العلا)", 
        "شاطئ شرما", "جبل السودة", "وادي طيب الاسم", 
        "جزر أملج", "جبل شدا الأعلى"
    ]

    print("Verifying and cleaning up spots in Firestore...")
    for name in spot_names:
        docs = list(db.collection('spots').where("name", "==", name).stream())
        print(f"Checking: {name} (Found {len(docs)} documents)")
        
        for doc in docs:
            data = doc.to_dict()
            is_uuid = False
            try:
                import uuid
                uuid.UUID(doc.id)
                is_uuid = True
            except ValueError:
                is_uuid = False
            
            if is_uuid:
                print(f"  ✅ [UUID] {doc.id}")
                print(f"     Coord: {data.get('latitude')}, {data.get('longitude')}")
            else:
                print(f"  🗑️ [Legacy] {doc.id} - Deleting...")
                doc.reference.delete()

if __name__ == "__main__":
    verify()
