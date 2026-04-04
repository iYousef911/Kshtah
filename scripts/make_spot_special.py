import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import time
import os

# Ensure credentials exist
cred_path = 'kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json'
if not os.path.exists(cred_path):
    cred_path = 'scripts/kashat-aea20-firebase-adminsdk-fbsvc-9f3de014fc.json'
if not os.path.exists(cred_path):
    print(f"Error: Could not find credentials file")
    exit(1)

cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

db = firestore.client()

def list_spots():
    print("\nFetching spots from Firestore...")
    spots_ref = db.collection('spots')
    docs = spots_ref.stream()
    
    spots = []
    for i, doc in enumerate(docs):
        data = doc.to_dict()
        spot_name = data.get('name', 'Unknown')
        is_special = data.get('isSpecial', False)
        spots.append({
            'id': doc.id,
            'name': spot_name,
            'isSpecial': is_special
        })
        status = "[🌟 المميز]" if is_special else ""
        print(f"[{i + 1}] {spot_name} {status}")
        
    return spots

def toggle_special_status(spot):
    doc_ref = db.collection('spots').document(spot['id'])
    new_status = not spot['isSpecial']
    
    try:
        doc_ref.update({
            'isSpecial': new_status
        })
        
        status_str = "ADDED to Special Spots!" if new_status else "REMOVED from Special Spots."
        print(f"\n✅ Success: '{spot['name']}' was {status_str}")
    except Exception as e:
        print(f"❌ Error updating document: {e}")

if __name__ == '__main__':
    print("================================")
    print(" Kashat Special Spots Manager ")
    print("================================")
    
    spots = list_spots()
    
    if not spots:
        print("No spots found in the database.")
        exit(0)
        
    print("\nSelect a spot to toggle its Special status.")
    print("Enter the number of the spot (or 'q' to quit):")
    
    choice = input("> ")
    
    if choice.lower() == 'q':
        print("Exiting...")
        exit(0)
        
    try:
        idx = int(choice) - 1
        if 0 <= idx < len(spots):
            toggle_special_status(spots[idx])
        else:
            print("Invalid selection.")
    except ValueError:
        print("Invalid input. Please enter a number.")
