from app.functions import *


@app.route("/api/records",methods = ['POST'])
def post_records():
    """
    Accept a JSON body with fog version, os name, and os version.
    Store this to the database.
    """
    if not request.is_json:
        return jsonify({"message":"Request is missing json"}),400

    os_name = ""
    os_version = ""
    fog_version = ""
    record = request.get_json()

    if "os_name" in record.keys():
        os_name = record["os_name"]
    if "os_version" in record.keys():
        os_version = record["os_version"]
    if "fog_version" in record.keys():
        fog_version = record["fog_version"]

    sql = "INSERT INTO popularity (os_name,os_version,fog_version) VALUES (" + escape(str(os_name)) + "," + escape(str(os_version)) + "," + escape(str(fog_version)) + ");"

    query(theSql=sql)

    return jsonify({"message":"record recorded"}),200



