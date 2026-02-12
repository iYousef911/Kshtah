import firebase_admin
from firebase_admin import credentials, firestore
import os

SERVICE_ACCOUNT_KEY_PATH = "scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def debug_dump():
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    spot_name = "حافة العالم"
    print(f"Dumping data for spot: {spot_name}")
    docs = db.collection('spots').where("name", "==", spot_name).limit(1).stream()
    doc = next(docs, None)
    if doc:
        print(f"Document ID: {doc.id}")
        data = doc.to_dict()
        for key, value in data.items():
            print(f"Key: {key}, Value: {value}, Type: {type(value)}")
    else:
        print("Spot not found")

if __name__ == "__main__":
    debug_dump()
