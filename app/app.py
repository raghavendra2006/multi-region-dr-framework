import os
import sqlite3
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)
DB_PATH = os.getenv('DB_PATH', '/data/application.db')

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS timestamps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            value TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok'}), 200

@app.route('/write', methods=['POST'])
def write_data():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    timestamp_val = datetime.now().isoformat()
    cursor.execute('INSERT INTO timestamps (value) VALUES (?)', (timestamp_val,))
    conn.commit()
    conn.close()
    return jsonify({'status': 'success', 'written': timestamp_val}), 201

@app.route('/data', methods=['GET'])
def read_data():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT value, created_at FROM timestamps ORDER BY id DESC')
    rows = cursor.fetchall()
    conn.close()
    return jsonify([{'value': row[0], 'created_at': row[1]} for row in rows])
    
if __name__=="__main__":
    init_db()
    app.run(host="0.0.0.0",port=5000)