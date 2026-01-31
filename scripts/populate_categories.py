import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os

# Configuration
SERVICE_ACCOUNT_KEY_PATH = "kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json"

def initialize_firebase():
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        print(f"Error: Service account key not found at {SERVICE_ACCOUNT_KEY_PATH}")
        return None

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    try:
        app = firebase_admin.get_app()
    except ValueError:
        app = firebase_admin.initialize_app(cred)
        
    return firestore.client()

def upload_categories(db):
    # Define Categories (Arabic Type Key matching data, Arabic Display Name, Icon, Sort Order)
    categories = [
        {"id": "all", "name": "الكل", "type": "الكل", "icon": "square.grid.2x2.fill", "sortOrder": 0},
        {"id": "camp", "name": "مخيمات", "type": "مخيمات", "icon": "tent.fill", "sortOrder": 1},
        {"id": "mountain", "name": "جبال", "type": "جبل", "icon": "mountain.2.fill", "sortOrder": 2}, # Type: Singular (matches data)
        {"id": "valley", "name": "وديان", "type": "وادي", "icon": "water.waves", "sortOrder": 3},
        {"id": "beach", "name": "شواطئ", "type": "شاطئ", "icon": "sun.max.fill", "sortOrder": 4},
        {"id": "sand", "name": "كثبان", "type": "كثبان", "icon": "wind", "sortOrder": 5},
        {"id": "lake", "name": "بحيرات", "type": "بحيرة", "icon": "drop.fill", "sortOrder": 6},
        
        # NEW Categories
        {"id": "heritage", "name": "تراث", "type": "تراث", "icon": "building.columns.fill", "sortOrder": 7},
        {"id": "island", "name": "جزر", "type": "جزيرة", "icon": "map.fill", "sortOrder": 8},
        {"id": "forest", "name": "غابات", "type": "غابة", "icon": "leaf.fill", "sortOrder": 9},
        {"id": "meadow", "name": "رياض", "type": "روضة", "icon": "tree.fill", "sortOrder": 10},
        {"id": "reserve", "name": "محميات", "type": "محمية", "icon": "bird.fill", "sortOrder": 11},
        {"id": "desert", "name": "صحراء", "type": "صحراء", "icon": "sun.haze.fill", "sortOrder": 12}
    ]

    collection_ref = db.collection('categories')
    
    print(f"Uploading {len(categories)} categories...")
    
    for cat in categories:
        doc_ref = collection_ref.document(cat["id"])
        data = {
            "name": cat["name"],
            "type": cat["type"],
            "icon": cat["icon"],
            "sortOrder": cat["sortOrder"],
            "isActive": True
        }
        doc_ref.set(data, merge=True)
        print(f"Set category: {cat['name']} ({cat['type']})")

    print("Categories upload complete!")

if __name__ == "__main__":
    db = initialize_firebase()
    if db:
        upload_categories(db)
