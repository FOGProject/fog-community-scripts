from app.functions import *


@app.route("/api/hello-world",methods = ['GET'])
def hello_world():
    """
    demonstrates a hello-world message.
    """
    return jsonify({"message":"hello world!"}),200



