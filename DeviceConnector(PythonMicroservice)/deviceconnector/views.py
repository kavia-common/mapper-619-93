import os
from . import app
from flask import jsonify

@app.route('/health')
def health():
    return jsonify(status='ok')

# device connector stub that respects DEVICE_LIB at runtime
def connect_stub():
    lib = os.environ.get('DEVICE_LIB','').lower()
    try:
        if lib == 'ncclient':
            import ncclient
            return True
        elif lib == 'netmiko':
            import netmiko
            return True
        else:
            return False
    except Exception:
        return False
