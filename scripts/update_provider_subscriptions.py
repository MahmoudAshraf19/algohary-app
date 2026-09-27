import json
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os
import random
import datetime

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate(r'D:\algohary_project\adminsdk.json')
    app = firebase_admin.initialize_app(cred)
    print("Firebase Admin SDK initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")
    exit(1)

# Initialize Firestore client for the 'algohary' named database
try:
    db = firestore.client(app=app, database_id='algohary')
    print("Connected to Firestore database 'algohary'.")
except Exception as e:
    print(f"Warning: Could not connect to 'algohary'. Falling back to default. Error: {e}")
    db = firestore.client(app=app)

def update_firestore_providers():
    # Load subscription plans
    plans_file_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'subscription_plans.json')
    with open(plans_file_path, 'r', encoding='utf-8') as f:
        plans = json.load(f)
    
    plan_dict = {plan['id']: plan for plan in plans if 'id' in plan}
    plan_ids = list(plan_dict.keys())
    if not plan_ids:
        print("No plan IDs found in subscription_plans.json")
        return

    # Get users with user_type == "provider"
    users_ref = db.collection('users')
    query = users_ref.where('user_type', '==', 'provider')
    docs = query.stream()
    
    updated_count = 0
    now = datetime.datetime.now(datetime.timezone.utc)
    
    for doc in docs:
        doc_data = doc.to_dict()
        subscription = doc_data.get('subscription', {})
        
        # In case a plan is already assigned, use it. Otherwise, assign one randomly.
        current_plan_id = subscription.get('plan')
        if not current_plan_id or current_plan_id not in plan_dict:
            current_plan_id = random.choice(plan_ids)
            subscription['plan'] = current_plan_id
            
        plan_details = plan_dict[current_plan_id]
        expiry_days_str = plan_details.get('expiryDay', '0')
        
        try:
            expiry_days = int(expiry_days_str)
        except ValueError:
            expiry_days = 0
            
        # Set start_date to today
        subscription['start_date'] = now
        
        # Calculate end_date based on plan's expiryDay
        if expiry_days == -1:
            subscription['end_date'] = None
        else:
            subscription['end_date'] = now + datetime.timedelta(days=expiry_days)
        
        # Set to active
        subscription['is_active'] = True
        subscription['is_subscribed'] = True
        
        # Update the document in Firestore
        try:
            # We use update to ONLY modify the subscription map
            doc.reference.update({
                'subscription': subscription
            })
            print(f"✅ Updated provider {doc.id} with start_date and end_date (Plan: {current_plan_id}, Days: {expiry_days})")
            updated_count += 1
        except Exception as e:
            print(f"❌ Failed to update provider {doc.id}: {e}")
            
    print(f"\n🎉 Successfully updated {updated_count} providers in Firestore!")

if __name__ == '__main__':
    update_firestore_providers()
