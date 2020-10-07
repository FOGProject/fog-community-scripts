#!/opt/external_reporting/flask/bin/python

import json
import MySQLdb as mysql
from boto3 import client
import os
from datetime import datetime


def query(theSql=None,json=False,single=False,getID=False):
    cursor = db.cursor()
    cursor.execute(theSql)
    rows = cursor.fetchall()
    queryType = theSql.split(' ')[0].upper()
    commitWords = ['INSERT','UPDATE','DELETE','REPLACE']
    if queryType in commitWords:
        db.commit()
    if json:
        columns = [desc[0] for desc in cursor.description]
        result = []
        for row in rows:
            row = dict(zip(columns, row))
            result.append(row)
    elif single:
        try:
            result = rows[0][0]
        except:
            result = None
    elif getID:
        result = cursor.lastrowid
    else:
        result = rows
    return result


# Load settings.
settingsFilePath = '/opt/external_reporting/settings.json'
with open(settingsFilePath, 'r') as settings_file:
    settings = json.loads(settings_file.read())


# Connect to database.
db = mysql.connect(host=settings['MYSQL_HOST'],user=settings['MYSQL_USER'],passwd=settings['MYSQL_PASSWORD'], db=settings['MYSQL_DB'], port=settings['MYSQL_PORT'])


# Create s3 client.
s3_client = client('s3')


# Get the date & time in a format useful for timestamps.
now = datetime.now()
format = "%Y-%m-%d_%H-%M-%S"
formatted_time = now.strftime(format)


# Dump the database
dump_command = "mysqldump -u " + settings["MYSQL_USER"] + " -p" + settings["MYSQL_PASSWORD"] + " -P " + str(settings["MYSQL_PORT"]) + " " + settings["MYSQL_DB"] + " > /tmp/db.sql"
os.system(dump_command)


# Compress the file.
compress_command = "tar -czf /tmp/db.tar.gz -C /tmp db.sql > /dev/null 2>&1"
os.system(compress_command)


# Upload database to "latest" filename as well as archived directory with a date.
s3_client.upload_file("/tmp/db.tar.gz", settings["s3_bucket_name"], "archive/" + formatted_time + "/db.tar.gz)




