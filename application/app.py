from flask import Flask, jsonify
import oracledb
from config import DB_USER, DB_PASSWORD, DB_DSN

app = Flask(__name__)

def get_connection():
    return oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)

@app.route('/')
def home():
    return 'PMBRS is alive'

@app.route('/health')
def health():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM dual")
        cursor.fetchone()
        conn.close()
        db_status = "OK"
    except Exception as e:
        db_status = f"FAIL: {str(e)}"
    return jsonify({"application": "OK", "database": db_status, "version": "1.0.0"})

@app.route('/batches')
def batches():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT batch_number, product_code, status, start_time, end_time FROM batch ORDER BY start_time DESC")
    columns = [col[0] for col in cursor.description]
    rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(rows)

@app.route('/equipment')
def equipment():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT equipment_name, area, status, last_updated FROM equipment ORDER BY equipment_name")
    columns = [col[0] for col in cursor.description]
    rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(rows)

@app.route('/events')
def events():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT pe.event_type, pe.description, pe.severity, pe.event_timestamp,
               b.batch_number, e.equipment_name
        FROM production_event pe
        LEFT JOIN batch b ON pe.batch_id = b.batch_id
        LEFT JOIN equipment e ON pe.equipment_id = e.equipment_id
        ORDER BY pe.event_timestamp DESC
    """)
    columns = [col[0] for col in cursor.description]
    rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
    conn.close()
    return jsonify(rows)