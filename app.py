# ============================================================
# app.py — The main application file
# This is a REST API built with Flask (a Python web framework)
# A REST API = a service that receives HTTP requests and returns JSON data
# ============================================================

# Flask  = the web framework (handles routing, requests, responses)
# request = lets us read data sent BY the client (example: POST body)
# jsonify = converts Python dict into JSON response
from flask import Flask, request, jsonify

# datetime = used to record when a note was created
from datetime import datetime

# os = used to read environment variables (like PORT number)
# Environment variables = settings we pass to the app from outside
import os


# Create the Flask app
# __name__ tells Flask where this file is located
app = Flask(__name__)


# ---- TEMPORARY STORAGE ----
# We store notes in a list (Python array) for now
# This means data is LOST when you restart the app
# In Step 8 we will replace this with a real Azure PostgreSQL database
notes = []
next_id = 1  # Auto-incrementing ID for each note


# ============================================================
# ENDPOINT 1: Health Check
# URL: GET /health
# Purpose: A simple way to check "is the app running?"
# Azure uses this to know if your container is healthy
# If this returns 200 OK, Azure knows the app is alive
# ============================================================
@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()  # current time in ISO format
    })


# ============================================================
# ENDPOINT 2: Get All Notes
# URL: GET /notes
# Purpose: Return all notes that have been created
# ============================================================
@app.route('/notes', methods=['GET'])
def get_notes():
    return jsonify({
        "notes": notes,       # the list of all notes
        "total": len(notes)   # how many notes exist
    })


# ============================================================
# ENDPOINT 3: Create a Note
# URL: POST /notes
# Purpose: Receive a new note from the client and save it
# The client sends JSON like: {"title": "...", "content": "..."}
# ============================================================
@app.route('/notes', methods=['POST'])
def create_note():
    global next_id  # we need to modify the global variable

    # Read the JSON body sent by the client
    data = request.get_json()

    # Validate — title is required, return error if missing
    if not data or 'title' not in data:
        return jsonify({"error": "title is required"}), 400  # 400 = Bad Request

    # Build the note object
    note = {
        "id": next_id,
        "title": data['title'],
        "content": data.get('content', ''),         # content is optional
        "created_at": datetime.now().isoformat()    # record when it was created
    }

    # Save it to our list and increment the ID counter
    notes.append(note)
    next_id += 1

    # Return the created note with 201 = Created (success)
    return jsonify(note), 201


# ============================================================
# START THE APP
# This block only runs when you do: python app.py directly
# When Docker runs it via gunicorn, this block is SKIPPED
# PORT comes from environment variable (default 5000)
# ============================================================
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
