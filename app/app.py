import logging
import os
import sqlite3
from datetime import datetime

from flask import Flask, jsonify

# Configure production logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
DB_PATH = os.getenv("DB_PATH", "/data/application.db")


def get_db_connection():
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as e:
        logger.error(f"Database connection failed: {e}")
        raise


def init_db():
    try:
        os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS timestamps (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                value TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        logger.info("Database initialized successfully.")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
    finally:
        if "conn" in locals() and conn:
            conn.close()


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"}), 200


@app.route("/write", methods=["POST"])
def write_data():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        timestamp_val = datetime.now().isoformat()
        cursor.execute(
            "INSERT INTO timestamps (value) VALUES (?)", (timestamp_val,)
        )
        conn.commit()
        logger.info(f"Successfully wrote record: {timestamp_val}")
        return jsonify({"status": "success", "written": timestamp_val}), 201
    except Exception as e:
        logger.error(f"Failed to write data: {e}")
        return jsonify({"status": "error", "message": "Internal Server Error"}), 500
    finally:
        if conn:
            conn.close()


@app.route("/data", methods=["GET"])
def read_data():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT value, created_at FROM timestamps ORDER BY id DESC")
        rows = cursor.fetchall()
        logger.info(f"Successfully retrieved {len(rows)} records.")
        return jsonify(
            [{"value": row["value"], "created_at": row["created_at"]} for row in rows]
        )
    except Exception as e:
        logger.error(f"Failed to read data: {e}")
        return jsonify(
            {"status": "error", "message": "Internal Server Error"}
        ), 500
    finally:
        if conn:
            conn.close()


# Initialize database on startup
init_db()

if __name__ == "__main__":
    logger.warning(
        "Running the built-in Flask development server is "
        "not recommended for production."
    )
    app.run(host="0.0.0.0", port=5000)
