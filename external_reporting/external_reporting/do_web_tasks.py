#!/opt/external_reporting/flask/bin/python

import json
import MySQLdb as mysql
from boto3 import client
import os
from datetime import datetime
from matplotlib import pyplot, figure
import numpy as np
from sys import exit


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

"""
# Number of fog systems running in the last 7 days.
select count(id) from versions_out_there where creation_time >= DATE(NOW()) - INTERVAL 7 DAY;
"""

# Create s3 client.
s3_client = client('s3')

# Get the date & time in a format useful for timestamps.
now = datetime.now()
format = "%Y-%m-%d_%H-%M-%S"
formatted_time = now.strftime(format)



# fog versions & counts from the last 7 days.
sql = "select distinct fog_version, count(*) as count from versions_out_there where id in (select id from versions_out_there where creation_time >= DATE(NOW()) - INTERVAL 7 DAY) GROUP BY fog_version ORDER BY count DESC limit 20;"
results = query(theSql=sql,json=True)
keys = [i["fog_version"] for i in results]
values = [i["count"] for i in results]
y_pos = np.arange(len(keys))
pyplot.bar(y_pos, values)
pyplot.xticks(y_pos, keys)
pyplot.xticks(rotation=-90)
pyplot.ylabel('Count')
pyplot.title('Top 20 FOG Versions in use')
pyplot.tick_params(axis='x', pad=-100) # This puts the tick labels onto the bars.
fig = pyplot.gcf()
fig.set_size_inches(12, 5)
fig.savefig('/tmp/fog_versions_and_counts.png', dpi=100)
s3_client.upload_file("/tmp/fog_versions_and_counts.png", settings["s3_bucket_name"], "archive/" + formatted_time + "/fog_versions_and_counts.png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/fog_versions_and_counts.png", settings["s3_bucket_name"], "fog_versions_and_counts.png", ExtraArgs={'ContentType': "image/png"})




# OS Names, Versions, and Counts in last 7 days.
sql = "SELECT DISTINCT os_name, os_version, count(*) as count FROM versions_out_there where id in (select id from versions_out_there where creation_time >= DATE(NOW()) - INTERVAL 7 DAY) group by os_name, os_version ORDER BY count DESC limit 20;"
results = query(theSql=sql,json=True)
keys = [i["os_name"] + " " + i["os_version"] for i in results]
values = [i["count"] for i in results]
y_pos = np.arange(len(keys))
pyplot.bar(y_pos, values)
pyplot.xticks(y_pos, keys)
pyplot.xticks(rotation=-90)
pyplot.ylabel('Count')
pyplot.title('Top 20 OS Versions in use')
pyplot.tick_params(axis='x', pad=-100) # This puts the tick labels onto the bars.
fig = pyplot.gcf()
fig.set_size_inches(12, 5)
fig.savefig('/tmp/os_names_versions_and_counts.png', dpi=100)
s3_client.upload_file("/tmp/os_names_versions_and_counts.png", settings["s3_bucket_name"], "archive/" + formatted_time + "/os_names_versions_and_counts.png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/os_names_versions_and_counts.png", settings["s3_bucket_name"], "os_names_versions_and_counts.png", ExtraArgs={'ContentType': "image/png"})




# OS names & counts from last 7 days.
sql = "select distinct os_name, count(*) as count from versions_out_there where id in (select id from versions_out_there where creation_time >= DATE(NOW()) - INTERVAL 7 DAY) group by os_name ORDER BY count DESC;"
results = query(theSql=sql,json=True)
keys = [i["os_name"] for i in results]
values = [i["count"] for i in results]
y_pos = np.arange(len(keys))
pyplot.bar(y_pos, values)
pyplot.xticks(y_pos, keys)
pyplot.xticks(rotation=-90)
pyplot.ylabel('Count')
pyplot.title('Top 20 OSs in use')
pyplot.tick_params(axis='x', pad=-100) # This puts the tick labels onto the bars.
fig = pyplot.gcf()
fig.set_size_inches(12, 5)
fig.savefig('/tmp/os_names_and_counts.png', dpi=100)
s3_client.upload_file("/tmp/os_names_and_counts.png", settings["s3_bucket_name"], "archive/" + formatted_time + "/os_names_and_counts.png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/os_names_and_counts.png", settings["s3_bucket_name"], "os_names_and_counts.png", ExtraArgs={'ContentType': "image/png"})







# Dump the database
dump_command = "mysqldump -u " + settings["MYSQL_USER"] + " -p" + settings["MYSQL_PASSWORD"] + " -P " + str(settings["MYSQL_PORT"]) + " " + settings["MYSQL_DB"] + " > /tmp/db.sql"
os.system(dump_command)


# Compress the file.
compress_command = "tar -czf /tmp/db.tar.gz -C /tmp db.sql > /dev/null 2>&1"
os.system(compress_command)


# Upload database to base and archived.
s3_client.upload_file("/tmp/db.tar.gz", settings["s3_bucket_name"], "archive/" + formatted_time + "/db.tar.gz")
s3_client.upload_file("/tmp/db.tar.gz", settings["s3_bucket_name"], "db.tar.gz")


# Upload the index.html file to base and archived..
s3_client.upload_file("/opt/external_reporting/index.html", settings["s3_bucket_name"], "archive/" + formatted_time + "/index.html", ExtraArgs={'ContentType': "text/html"})
s3_client.upload_file("/opt/external_reporting/index.html", settings["s3_bucket_name"], "index.html", ExtraArgs={'ContentType': "text/html"})





