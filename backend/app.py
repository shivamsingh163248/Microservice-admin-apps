from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import os
import time
import jwt
import datetime
from functools import wraps

app = Flask(__name__)
# Configure CORS to allow requests from frontend
CORS(app, origins=["http://localhost:8080", "http://127.0.0.1:8080", "http://frontend:80"])

# Secret key for JWT tokens
app.config['SECRET_KEY'] = 'your-secret-key-here-change-in-production'

# Active sessions storage (in production, use Redis or database)
active_sessions = {
    'user_sessions': {},
    'admin_sessions': {}
}

# JWT token generation
def generate_token(user_type, username):
    payload = {
        'user_type': user_type,
        'username': username,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }
    return jwt.encode(payload, app.config['SECRET_KEY'], algorithm='HS256')

# JWT token validation decorator
def token_required(user_type):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            token = request.headers.get('Authorization')
            if not token:
                return jsonify({'message': 'Token is missing!'}), 401
            
            try:
                if token.startswith('Bearer '):
                    token = token[7:]
                
                data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
                
                # Check if token type matches required type
                if data['user_type'] != user_type:
                    return jsonify({'message': 'Invalid token type!'}), 401
                
                # Check if session is still active
                session_key = f"{data['username']}_{data['user_type']}"
                if user_type == 'admin':
                    if session_key not in active_sessions['admin_sessions']:
                        return jsonify({'message': 'Session expired!'}), 401
                else:
                    if session_key not in active_sessions['user_sessions']:
                        return jsonify({'message': 'Session expired!'}), 401
                
                request.current_user = data['username']
                request.user_type = data['user_type']
                
            except jwt.ExpiredSignatureError:
                return jsonify({'message': 'Token has expired!'}), 401
            except jwt.InvalidTokenError:
                return jsonify({'message': 'Token is invalid!'}), 401
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# Function to connect to MySQL database with retries
def connect_to_database():
    max_retries = 30
    retry_delay = 2
    
    for attempt in range(max_retries):
        try:
            print(f"Attempting to connect to database (attempt {attempt + 1}/{max_retries})")
            db = mysql.connector.connect(
                host=os.getenv("DB_HOST", "database"),
                user=os.getenv("DB_USER", "adminuser"),
                password=os.getenv("DB_PASS", "adminpass"),
                database=os.getenv("DB_NAME", "adminapp")
            )
            print("Successfully connected to database!")
            return db
        except mysql.connector.Error as e:
            print(f"Database connection failed: {e}")
            if attempt < max_retries - 1:
                print(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                print("Max retries reached. Exiting.")
                raise e

# Global variables for database connection
db = None
cursor = None

def get_db_connection():
    global db, cursor
    if db is None:
        print("Initializing database connection...")
        db = connect_to_database()
        cursor = db.cursor()
    return db, cursor

@app.route('/register', methods=['POST'])
def register():
    try:
        db, cursor = get_db_connection()
        data = request.get_json()
        cursor.execute("INSERT INTO users (username, password) VALUES (%s, %s)", (data['username'], data['password']))
        db.commit()
        return jsonify({"message": "Registration successful"})
    except Exception as e:
        print(f"Registration error: {e}")
        return jsonify({"message": "Registration failed"}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        db, cursor = get_db_connection()
        data = request.get_json()
        cursor.execute("SELECT * FROM users WHERE username=%s AND password=%s", (data['username'], data['password']))
        user = cursor.fetchone()
        if user:
            # Generate token
            token = generate_token('user', data['username'])
            
            # Store session
            session_key = f"{data['username']}_user"
            active_sessions['user_sessions'][session_key] = {
                'username': data['username'],
                'login_time': datetime.datetime.utcnow(),
                'token': token
            }
            
            return jsonify({
                "message": "Login successful",
                "token": token,
                "username": data['username']
            })
        else:
            return jsonify({"message": "Invalid credentials"}), 401
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({"message": "Login failed"}), 500

@app.route('/admin-login', methods=['POST'])
def admin_login():
    data = request.get_json()
    if data['username'] == 'admin' and data['password'] == 'admin123':
        # Generate admin token
        token = generate_token('admin', 'admin')
        
        # Store admin session
        session_key = "admin_admin"
        active_sessions['admin_sessions'][session_key] = {
            'username': 'admin',
            'login_time': datetime.datetime.utcnow(),
            'token': token
        }
        
        return jsonify({
            "message": "Admin Login successful",
            "token": token,
            "username": "admin"
        })
    else:
        return jsonify({"message": "Unauthorized"}), 401

@app.route('/users', methods=['GET'])
@token_required('admin')
def get_users():
    try:
        db, cursor = get_db_connection()
        cursor.execute("SELECT username FROM users")
        users = [row[0] for row in cursor.fetchall()]
        return jsonify(users)
    except Exception as e:
        print(f"Get users error: {e}")
        return jsonify({"message": "Failed to fetch users"}), 500

@app.route('/user-dashboard', methods=['GET'])
@token_required('user')
def user_dashboard():
    return jsonify({
        "message": "Welcome to user dashboard",
        "username": request.current_user
    })

@app.route('/admin-dashboard', methods=['GET'])
@token_required('admin')
def admin_dashboard():
    try:
        db, cursor = get_db_connection()
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        return jsonify({
            "message": "Welcome to admin dashboard",
            "user_count": user_count,
            "admin": request.current_user
        })
    except Exception as e:
        print(f"Admin dashboard error: {e}")
        return jsonify({"message": "Dashboard error"}), 500

@app.route('/logout', methods=['POST'])
def logout():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'message': 'No token provided'}), 400
    
    try:
        if token.startswith('Bearer '):
            token = token[7:]
        
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        session_key = f"{data['username']}_{data['user_type']}"
        
        # Remove session
        if data['user_type'] == 'admin':
            active_sessions['admin_sessions'].pop(session_key, None)
        else:
            active_sessions['user_sessions'].pop(session_key, None)
        
        return jsonify({'message': 'Logout successful'})
    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'}), 400

@app.route('/verify-session', methods=['GET'])
def verify_session():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'valid': False, 'message': 'No token provided'}), 401
    
    try:
        if token.startswith('Bearer '):
            token = token[7:]
        
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        session_key = f"{data['username']}_{data['user_type']}"
        
        # Check if session exists
        if data['user_type'] == 'admin':
            session_exists = session_key in active_sessions['admin_sessions']
        else:
            session_exists = session_key in active_sessions['user_sessions']
        
        if session_exists:
            return jsonify({
                'valid': True,
                'username': data['username'],
                'user_type': data['user_type']
            })
        else:
            return jsonify({'valid': False, 'message': 'Session expired'}), 401
            
    except jwt.ExpiredSignatureError:
        return jsonify({'valid': False, 'message': 'Token expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'valid': False, 'message': 'Invalid token'}), 401

@app.route('/health', methods=['GET'])
def health_check():
    try:
        db, cursor = get_db_connection()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        if result:
            return jsonify({
                "status": "healthy",
                "database": "connected",
                "message": "Database connection successful"
            })
    except Exception as e:
        print(f"Health check error: {e}")
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }), 500

@app.route('/db-info', methods=['GET'])
def database_info():
    try:
        db, cursor = get_db_connection()
        
        # Get database version
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()[0]
        
        # Get current database
        cursor.execute("SELECT DATABASE()")
        current_db = cursor.fetchone()[0]
        
        # Get tables in database
        cursor.execute("SHOW TABLES")
        tables = [row[0] for row in cursor.fetchall()]
        
        # Get user count
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        return jsonify({
            "database_version": version,
            "current_database": current_db,
            "tables": tables,
            "total_users": user_count,
            "connection_status": "success"
        })
    except Exception as e:
        print(f"Database info error: {e}")
        return jsonify({
            "error": str(e),
            "connection_status": "failed"
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
