from flask import Flask, request, jsonify
from pymongo import MongoClient
from datetime import datetime
import os

app = Flask(__name__)

MONGO_USERNAME = os.getenv('MONGO_USERNAME', 'admin')
MONGO_PASSWORD = os.getenv('MONGO_PASSWORD', 'password123')
MONGO_HOST = os.getenv('MONGO_HOST', 'mongodb-service')
MONGO_PORT = os.getenv('MONGO_PORT', '27017')
MONGO_AUTH_DB = os.getenv('MONGO_AUTH_DB', 'admin')

MONGO_URI = f"mongodb://{MONGO_USERNAME}:{MONGO_PASSWORD}@{MONGO_HOST}:{MONGO_PORT}/?authSource={MONGO_AUTH_DB}"

print(f"Connecting to MongoDB at: mongodb://{MONGO_USERNAME}:****@{MONGO_HOST}:{MONGO_PORT}")

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command('ping')
    print("Successfully connected to MongoDB!")
    
    db = client['flaskdb']
    collection = db['data']
except Exception as e:
    print(f"✗ Error connecting to MongoDB: {e}")
    client = None
    db = None
    collection = None

@app.route('/')
def index():
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"Welcome to the Flask app! The current time is: {current_time}"

@app.route('/data', methods=['GET', 'POST'])
def data():
    """
    Data endpoint for MongoDB operations:
    - POST: Insert new data into MongoDB
    - GET: Retrieve all data from MongoDB
    """
    if collection is None:
        return jsonify({"error": "Database connection not available"}), 503
    
    if request.method == 'POST':
        try:
            payload = request.get_json()
            
            if not payload:
                return jsonify({"error": "Invalid or missing JSON"}), 400
            
            payload['timestamp'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            result = collection.insert_one(payload)
            
            return jsonify({
                "status": "Data inserted successfully",
                "id": str(result.inserted_id),
                "data": payload
            }), 201
            
        except Exception as e:
            return jsonify({"error": f"Failed to insert data: {str(e)}"}), 500
    
    elif request.method == 'GET':
        try:
            docs = list(collection.find({}, {"_id": 0}))
            
            return jsonify({
                "count": len(docs),
                "data": docs
            }), 200
            
        except Exception as e:
            return jsonify({"error": f"Failed to retrieve data: {str(e)}"}), 500

@app.route('/health')
def health():
    """
    Health check endpoint for Kubernetes probes
    Returns 200 if healthy, 500 if unhealthy
    """
    try:
        if client is None:
            return jsonify({
                "status": "unhealthy",
                "database": "disconnected"
            }), 500
        
        # Ping MongoDB to check connection
        client.admin.command('ping')
        
        return jsonify({
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "error": str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)