# -*- coding: utf-8 -*-
"""
Offline Launcher for PhanMemPC06_Pro
- Auto-register to start with Windows when first run
- Auto-start hidden with auto-restart on crash
"""

import os
import sys
import io
import signal
import time

# Fix encoding for console output
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
if sys.stderr.encoding != 'utf-8':
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from datetime import datetime

# File lock để bảo vệ server
LOCK_FILE = '.server.lock'

# Xác định thư mục executable
if getattr(sys, 'frozen', False):
    APP_DIR = sys._MEIPASS
    BASE_DIR = os.path.dirname(sys.executable)
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    APP_DIR = BASE_DIR

SERVER_PORT = 5000
os.chdir(BASE_DIR)

# ===== QUẢN LÝ KHỞI ĐỘNG CÙNG WINDOWS =====
STARTUP_FILE = os.path.join(os.path.expandvars('%APPDATA%'), 
    'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup', 'PC06_Server.bat')

def register_autostart():
    """Đăng ký khởi động cùng Windows"""
    if os.path.exists(STARTUP_FILE):
        return True
    
    try:
        # Tạo file khởi động với tham số --hidden --auto
        with open(STARTUP_FILE, 'w', encoding='utf-8') as f:
            f.write(f'@echo off\n"{os.path.join(BASE_DIR, "PhanMemPC06_Server.exe")}" --auto\n')
        return True
    except:
        return False

def unregister_autostart():
    """Hủy đăng ký khởi động cùng Windows"""
    try:
        if os.path.exists(STARTUP_FILE):
            os.remove(STARTUP_FILE)
        return True
    except:
        return False

# ===== FILE LOCK =====
def create_lock_file():
    try:
        with open(os.path.join(BASE_DIR, LOCK_FILE), 'w') as f:
            f.write(str(os.getpid()))
        return True
    except:
        return False

def remove_lock_file():
    try:
        lock_path = os.path.join(BASE_DIR, LOCK_FILE)
        if os.path.exists(lock_path):
            os.remove(lock_path)
        return True
    except:
        return False

def check_lock():
    lock_path = os.path.join(BASE_DIR, LOCK_FILE)
    if os.path.exists(lock_path):
        try:
            with open(lock_path, 'r') as f:
                pid = int(f.read().strip())
            os.kill(pid, 0)
            return True
        except:
            os.remove(lock_path)
            return False
    return False

# ===== THƯ MỤC CẦN THIẾT =====
def ensure_dirs():
    for d in ['uploads', 'backups', 'logs', 'task_files', 'library_files', 'tmp']:
        path = os.path.join(BASE_DIR, d)
        if not os.path.exists(path):
            os.makedirs(path, exist_ok=True)

# ===== DATABASE =====
def init_database():
    db_path = os.path.join(BASE_DIR, 'pc06_system.db')
    if not os.path.exists(db_path):
        print("[INIT] Đang tạo database...")
        sys.path.insert(0, BASE_DIR)
        try:
            from models import db
            from utils import init_db
            from flask import Flask
            app = Flask(__name__)
            app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
            app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
            db.init_app(app)
            with app.app_context():
                init_db(app)
            print("[OK] Database đã tạo!")
            return True
        except Exception as e:
            print(f"[ERROR] {e}")
            return False
    return True

# ===== LẤY IP =====
def get_local_ip():
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

# ===== SIGNAL HANDLERS =====
def signal_handler(signum, frame):
    print("\n[INFO] Server dừng...")
    remove_lock_file()
    sys.exit(0)

if hasattr(signal, 'SIGTERM'):
    signal.signal(signal.SIGTERM, signal_handler)
if hasattr(signal, 'SIGINT'):
    signal.signal(signal.SIGINT, signal_handler)

# ===== SERVER =====
def start_server():
    if BASE_DIR not in sys.path:
        sys.path.insert(0, BASE_DIR)
    
    try:
        import app as flask_app
        
        print("-" * 50)
        print("   TRUY CẬP: http://localhost:5000")
        print("   NETWORK:  http://{}:5000".format(get_local_ip()))
        print("-" * 50)
        print()
        
        from waitress import serve
        serve(flask_app.app, host='0.0.0.0', port=SERVER_PORT)
        return True
        
    except Exception as e:
        print(f"[ERROR] {e}")
        import traceback
        traceback.print_exc()
        return False

# ===== AUTO RESTART =====
def run_with_auto_restart():
    max_retries = 10
    retry_count = 0
    restart_delay = 5
    
    while retry_count < max_retries:
        try:
            create_lock_file()
            success = start_server()
            if success:
                break
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"[ERROR] {e}")
            retry_count += 1
            if retry_count < max_retries:
                print(f"[INFO] Khởi động lại sau {restart_delay}s...")
                time.sleep(restart_delay)
                restart_delay = min(restart_delay * 2, 30)
    
    remove_lock_file()

# ===== MAIN =====
if __name__ == '__main__':
    # Kiểm tra server đang chạy
    if check_lock():
        print("[CẢNH BÁO] Server đang chạy!")
        print("[INFO] Chạy STOP_Server.bat để dừng")
        input("\nNhấn Enter...")
        sys.exit(1)
    
    # Đăng ký khởi động cùng Windows (auto cho lần sau)
    if '--no-autostart' not in sys.argv:
        register_autostart()
    
    # Hiển thị banner
    os.system('cls' if os.name == 'nt' else 'clear')
    print("=" * 50)
    print("   PHẦN MỀM QUẢN LÝ PC06 - OFFLINE")
    print("=" * 50)
    print(f"   Phiên bản: 3.5.0")
    print(f"   Khởi động: {datetime.now().strftime('%H:%M:%S %d/%m/%Y')}")
    print(f"   Port: {SERVER_PORT}")
    print("=" * 50)
    print()
    
    ensure_dirs()
    init_database()
    
    # Luôn chạy với auto-restart
    run_with_auto_restart()
