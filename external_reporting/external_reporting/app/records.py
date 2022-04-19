from asyncio.windows_events import NULL
from app.functions import *


@app.route("/api/records",methods = ['POST'])
def post_records():
    """
    Accept a JSON body with fog version, os name, os version, and kernel versions information.
    Store this to the database.

    Example JSON body:

```
{
  "fog_version": "1.5.9.139",
  "os_name": "Debian",
  "os_version": "11",
  "kernel_versions_info": [
    "bzImage32 5.15.19 (buildkite-agent@Tollana) #1 SMP Thu Feb 3 15:05:47 CST 2022",
    "bzImage 5.15.19 (buildkite-agent@Tollana) #1 SMP Thu Feb 3 15:10:05 CST 2022",
    "arm_Image_test little-endian",
    "another_test_kernel 4.19.145 (sebastian@Tollana) #1 SMP Sun Sep 13 05:43:10 CDT 2020"
  ]
}
```

    """
    if not request.is_json:
        return jsonify({"message":"Request is missing json"}),400

    record = request.get_json()

    os_name = db.escape_string(record.get("os_name", "")).decode("utf-8")
    os_version = db.escape_string(record.get("os_version", "")).decode("utf-8")
    fog_version = db.escape_string(record.get("fog_version", "")).decode("utf-8")
    kernel_versions_info = db.escape_string(record.get("kernel_versions_info", "")).decode("utf-8")

    sql = "INSERT INTO versions_out_there (os_name,os_version,fog_version) VALUES ('" + os_name + "','" + os_version + "','" + fog_version + "');"

    query(theSql=sql)


    # Check format of kernel_versions_info
    if type(kernel_versions_info) != list:
        return jsonify({"message":"kernel_versions_info is not a list"}),400

    # Format the sql.
    kernel_count = 0
    sql = "INSERT INTO kernels_out_there (kernel_version) VALUES "
    for kernel_version in kernel_versions_info:
        # Check for blank and null.
        if kernel_version == "" or kernel_version is NULL:
            continue
        # Trim to be less than 255 characters.
        new_kernel_version = kernel_version[:254]
        if sql[-1] == ")":
            sql = sql + ",('" + str(new_kernel_version) + "')"
        else:
            sql = sql + "('" + str(new_kernel_version) + "')"
        kernel_count = kernel_count + 1
    sql = sql + ";"

    # Insert the sql
    if kernel_count > 0:
        query(theSql=sql)

    return jsonify({"message":"record recorded"}),201
