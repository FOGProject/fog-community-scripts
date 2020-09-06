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

    os_name = record.get("os_name", "")
    os_version = record.get("os_version", "")
    fog_version = record.get("fog_version", "")

    sql = "INSERT INTO popularity (os_name,os_version,fog_version) VALUES (" + escape(str(os_name)) + "," + escape(str(os_version)) + "," + escape(str(fog_version)) + ");"

    query(theSql=sql)

    return jsonify({"message":"record recorded"}),200



