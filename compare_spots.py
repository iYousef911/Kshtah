import firebase_admin
from firebase_admin import credentials, firestore
import os

SERVICE_ACCOUNT_KEY_PATH = "scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def compare_spots():
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    print("Listing first 10 spots for comparison...")
    docs = db.collection('spots').limit(10).stream()
    for doc in docs:
        print(f"ID: {doc.id}")
        data = doc.to_dict()
        print(f"  Name: {data.get('name')}")
        print(f"  Fields: {list(data.keys())}")
        if 'latitude' in data:
            print(f"  Lat Type: {type(data['latitude'])}")
        print("-" * 20)

if __name__ == "__main__":
    compare_spots()
