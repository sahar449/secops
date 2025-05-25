from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World from Sahar Bittman – this container image is signed with Cosign and secured by Kyverno."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
