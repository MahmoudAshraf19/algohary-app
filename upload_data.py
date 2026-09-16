import json
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os
from datetime import datetime

def convert_timestamps(item):
    if not isinstance(item, dict): return item
    for key, val in item.items():
        if isinstance(val, str) and (key.endswith('_at') or key.endswith('_date')):
            try:
                item[key] = datetime.fromisoformat(val.replace('Z', '+00:00'))
            except ValueError:
                pass
        elif isinstance(val, dict):
            item[key] = convert_timestamps(val)
        elif isinstance(val, list):
            item[key] = [convert_timestamps(v) if isinstance(v, dict) else v for v in val]
    return item

def main():
    print("Initializing Firebase Admin SDK...")
    cred = credentials.Certificate('adminsdk.json')
    app = firebase_admin.initialize_app(cred)
    
    # Try connecting to the specific 'algohary' database
    print("Connecting to Firestore database 'algohary'...")
    try:
        db = firestore.client(app=app, database_id='algohary')
    except TypeError:
        # Fallback if the firebase-admin version doesn't support database_id in client()
        print("Fallback to google-cloud-firestore client for named database...")
        from google.cloud import firestore as google_firestore
        db = google_firestore.Client(
            credentials=cred.get_credential(),
            project=app.project_id,
            database='algohary'
        )
    
    # upload_json_to_firestore(db, 'categories', 'assets/data/categories.json')
    # upload_json_to_firestore(db, 'services', 'assets/data/services.json')
    # upload_json_to_firestore(db, 'governorates', 'assets/data/governorates.json')
    # upload_json_to_firestore(db, 'cities', 'assets/data/cities.json')
    
    upload_json_to_firestore(db, 'users', 'assets/data/providers.json')

def upload_json_to_firestore(db, collection_name, json_file_path):
    print(f"\n--- Starting upload for {collection_name} ---")
    if not os.path.exists(json_file_path):
        print(f"ERROR: File {json_file_path} not found.")
        return

    try:
        with open(json_file_path, 'r', encoding='utf-8') as file:
            data = json.load(file)
    except Exception as e:
        print(f"ERROR: Failed to read {json_file_path}: {e}")
        return

    collection_ref = db.collection(collection_name)
    count = 0
    
    # Handle phpMyAdmin JSON export format
    if isinstance(data, list):
        for item in data:
            if isinstance(item, dict) and item.get("type") == "table" and "data" in item:
                data = item["data"]
                break
                
    # If the JSON is wrapped in a single root key matching the collection name
    elif isinstance(data, dict) and len(data) == 1 and collection_name in data and isinstance(data[collection_name], list):
        data = data[collection_name]
        
    if isinstance(data, list):
        for item in data:
            if not isinstance(item, dict):
                continue
            item = convert_timestamps(item)
            doc_id = item.pop('id', None)
            if doc_id:
                collection_ref.document(str(doc_id)).set(item)
            else:
                collection_ref.add(item)
            count += 1
    elif isinstance(data, dict):
        for key, item in data.items():
            if isinstance(item, dict):
                item = convert_timestamps(item)
            collection_ref.document(str(key)).set(item)
            count += 1
            
    print(f"SUCCESS: Uploaded {count} items to '{collection_name}' collection.")

if __name__ == '__main__':
    main()
