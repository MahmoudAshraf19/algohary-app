import firebase_admin
from firebase_admin import credentials, firestore, messaging
import time
import threading

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r"D:\algohary_project\adminsdk.json")
# If you created a specific database named 'algohary' in Firestore, pass it here, otherwise it uses default
app = firebase_admin.initialize_app(cred)
db = firestore.client()

def send_fcm_notification(token, title, body):
    if not token:
        print("No FCM token found for user.")
        return
        
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
    )
    
    try:
        response = messaging.send(message)
        print('Successfully sent message:', response)
    except Exception as e:
        print('Error sending message:', e)

def on_snapshot(col_snapshot, changes, read_time):
    print(u'Received document snapshot.')
    for change in changes:
        if change.type.name == 'ADDED':
            doc = change.document
            data = doc.to_dict()
            
            # We are listening to users/{userId}/notifications
            # We can extract userId from the document reference
            user_id = doc.reference.parent.parent.id
            
            # Skip if already processed (could check a field like 'isSent' if you want)
            if data.get('type') == 'subscription':
                print(f"New subscription notification for user {user_id}: {data['title']}")
                
                # Fetch user's FCM token
                user_doc = db.collection('users').document(user_id).get()
                if user_doc.exists:
                    user_data = user_doc.to_dict()
                    fcm_token = user_data.get('fcm_token')
                    
                    if fcm_token:
                        send_fcm_notification(fcm_token, data.get('title'), data.get('body'))
                    else:
                        print(f"User {user_id} has no FCM token.")
                
def listen_to_notifications():
    print("Starting FCM Listener for notifications...")
    
    # We use a collection group query to listen to ALL 'notifications' subcollections
    # Make sure you have created an index in Firestore for collection group 'notifications' if needed.
    col_query = db.collection_group('notifications')
    
    # Watch the collection query
    query_watch = col_query.on_snapshot(on_snapshot)
    
    # Keep the script running
    while True:
        time.sleep(1)

if __name__ == '__main__':
    listen_to_notifications()
