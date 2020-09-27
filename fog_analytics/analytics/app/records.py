from app.functions import *


@app.route("/api/records",methods = ['POST'])
def post_records():
    """
    Accept a JSON body with fog version, os name, and os version.
    Store this to the database.
    """
    if not request.is_json:
        return jsonify({"message":"Request is missing json"}),400

    record = request.get_json()

    os_name = db.escape_string(record.get("os_name", "")).decode("utf-8")
    os_version = db.escape_string(record.get("os_version", "")).decode("utf-8")
    fog_version = db.escape_string(record.get("fog_version", "")).decode("utf-8")

    sql = "INSERT INTO versions_out_there (os_name,os_version,fog_version) VALUES ('" + os_name + "','" + os_version + "','" + fog_version + "');"

    query(theSql=sql)

    return jsonify({"message":"record recorded"}),200



