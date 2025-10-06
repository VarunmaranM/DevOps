from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    # This build tag is passed in from the Kubernetes deployment
    build_tag = os.environ.get('BUILD_TAG', 'unknown-local-build')
    return f"<h1>Hello from Your Live Application!</h1><p>This is build version: <strong>{build_tag}</strong></p>"

# Kubernetes uses this endpoint to check if your application is ready to receive traffic
@app.route('/health')
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)