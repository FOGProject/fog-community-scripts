#!/opt/external_reporting/flask/bin/python


from json import loads, dumps
import MySQLdb as mysql
from boto3 import client
import os
from datetime import datetime
from matplotlib import pyplot, figure
import numpy as np
from sys import exit


def write_json(JSON,file,indent=True):
    if indent:
        string = dumps(JSON, indent=4)
    else:
        string = dumps(JSON)
    fh = open(file,'w')
    fh.write(string)
    fh.close()


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
    settings = loads(settings_file.read())


# Connect to database.
db = mysql.connect(host=settings['MYSQL_HOST'],user=settings['MYSQL_USER'],passwd=settings['MYSQL_PASSWORD'], db=settings['MYSQL_DB'], port=settings['MYSQL_PORT'])


# Create s3 client.
s3_client = client('s3')


# Get the date & time in a format useful for timestamps.
now = datetime.now()
format = "%Y-%m-%d_%H-%M-%S"
formatted_time = now.strftime(format)



# Initialize a JSON object that will contain all the data.
data = {}





# Get number of fog systems in last 7 days.
sql = "select count(id) from versions_out_there where creation_time >= NOW() - INTERVAL 7 DAY;"
number_of_fog_systems = query(theSql=sql,single=True)
data["number_of_fog_systems"] = number_of_fog_systems



# fog versions & counts from the last N days.
distinct_number_to_report = "30" # must be a string.
key_name = "fog_versions_and_counts" # must be a string.
sql = "select distinct fog_version, count(*) as count from versions_out_there where id in (select id from versions_out_there where creation_time >= NOW() - INTERVAL 7 DAY) GROUP BY fog_version ORDER BY count DESC limit " + distinct_number_to_report + ";"
results = query(theSql=sql,json=True)
keys = [i["fog_version"] for i in results]
values = [i["count"] for i in results]
data[key_name] = {}
for key,value in zip(keys,values):
    data[key_name][key] = value
keys.reverse()
values.reverse()
y_pos = np.arange(len(keys))
pyplot.barh(y_pos, values)
pyplot.yticks(y_pos, keys)
pyplot.xlabel('Count')
pyplot.title('Top ' + distinct_number_to_report + ' FOG Versions in use')
ax = pyplot.gca()
ax.xaxis.grid() # vertical lines
fig = pyplot.gcf()
fig.set_size_inches(15, 10)
fig.savefig('/tmp/' + key_name + '.png', dpi=100, bbox_inches='tight')
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], "archive/" + formatted_time + "/" + key_name + ".png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"],  key_name + ".png", ExtraArgs={'ContentType': "image/png"})
pyplot.clf()




# OS Names, Versions, and Counts in last N days.
distinct_number_to_report = "30" # must be a string.
key_name = "os_names_versions_and_counts" # must be a string.
sql = "SELECT DISTINCT os_name, os_version, count(*) as count FROM versions_out_there where id in (select id from versions_out_there where creation_time >= NOW() - INTERVAL 7 DAY) group by os_name, os_version ORDER BY count DESC limit " + distinct_number_to_report + ";"
results = query(theSql=sql,json=True)
keys = [i["os_name"] + " " + i["os_version"] for i in results]
values = [i["count"] for i in results]
data[key_name] = {}
for key,value in zip(keys,values):
    data[key_name][key] = value
keys.reverse()
values.reverse()
y_pos = np.arange(len(keys))
pyplot.barh(y_pos, values)
pyplot.yticks(y_pos, keys)
pyplot.xlabel('Count')
pyplot.title('Top ' + distinct_number_to_report + ' OS Versions in use')
ax = pyplot.gca()
ax.xaxis.grid() # vertical lines
fig = pyplot.gcf()
fig.set_size_inches(15, 10)
fig.savefig('/tmp/' + key_name + '.png', dpi=100, bbox_inches='tight')
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], "archive/" + formatted_time + "/" + key_name + ".png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], key_name + ".png", ExtraArgs={'ContentType': "image/png"})
pyplot.clf()




# OS names & counts from last N days.
key_name = "os_names_and_counts" # must be a string.
sql = "select distinct os_name, count(*) as count from versions_out_there where id in (select id from versions_out_there where creation_time >= NOW() - INTERVAL 7 DAY) group by os_name ORDER BY count DESC;"
results = query(theSql=sql,json=True)
keys = [i["os_name"] for i in results]
values = [i["count"] for i in results]
data[key_name] = {}
for key,value in zip(keys,values):
    data[key_name][key] = value
keys.reverse()
values.reverse()
y_pos = np.arange(len(keys))
pyplot.barh(y_pos, values)
pyplot.yticks(y_pos, keys)
pyplot.xlabel('Count')
pyplot.title('Top OSs in use')
ax = pyplot.gca()
ax.xaxis.grid() # vertical lines
fig = pyplot.gcf()
fig.set_size_inches(15, 10)
fig.savefig('/tmp/' + key_name + '.png', dpi=100, bbox_inches='tight')
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], "archive/" + formatted_time + "/" + key_name + ".png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], key_name + ".png", ExtraArgs={'ContentType': "image/png"})
pyplot.clf()




# Kernel names and counts for last N days.
distinct_number_to_report = "30" # must be a string.
key_name = "kernels_out_there" # must be a string.
sql = "SELECT DISTINCT kernel_version, count(*) as count FROM kernels_out_there where id in (select id from kernels_out_there where creation_time >= NOW() - INTERVAL 7 DAY) group by kernel_version ORDER BY count DESC limit " + distinct_number_to_report + ";"
results = query(theSql=sql,json=True)
keys = [i["kernel_version"] for i in results]
values = [i["count"] for i in results]
data[key_name] = {}
for key,value in zip(keys,values):
    data[key_name][key] = value
keys.reverse()
values.reverse()
y_pos = np.arange(len(keys))
pyplot.barh(y_pos, values)
pyplot.yticks(y_pos, keys)
pyplot.xlabel('Count')
pyplot.title('Top ' + distinct_number_to_report + ' Kernel Versions in use')
ax = pyplot.gca()
ax.xaxis.grid() # vertical lines
fig = pyplot.gcf()
fig.set_size_inches(15, 10)
fig.savefig('/tmp/os_names_versions_and_counts.png', dpi=100, bbox_inches='tight')
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], "archive/" + formatted_time + "/" + key_name + ".png", ExtraArgs={'ContentType': "image/png"})
s3_client.upload_file("/tmp/" + key_name + ".png", settings["s3_bucket_name"], key_name + ".png", ExtraArgs={'ContentType': "image/png"})
pyplot.clf()




# Write JSON data to file and upload to S3
write_json(data,"/tmp/external_reporting.json")
s3_client.upload_file("/tmp/external_reporting.json", settings["s3_bucket_name"], "external_reporting.json")


# Dump the database
dump_command = "mysqldump -u " + settings["MYSQL_USER"] + " -p" + settings["MYSQL_PASSWORD"] + " -P " + str(settings["MYSQL_PORT"]) + " " + settings["MYSQL_DB"] + " > /tmp/db.sql"
os.system(dump_command)


# Compress the file.
compress_command = "tar -czf /tmp/db.tar.gz -C /tmp db.sql > /dev/null 2>&1"
os.system(compress_command)


# Upload database to base and archived.
s3_client.upload_file("/tmp/db.tar.gz", settings["s3_bucket_name"], "archive/" + formatted_time + "/db.tar.gz")
s3_client.upload_file("/tmp/db.tar.gz", settings["s3_bucket_name"], "db.tar.gz")


# Copy index.html to temp and replace the timestamp and count.
the_command = "cp /opt/external_reporting/index.html /tmp/index.html"
os.system(the_command)
the_command = "sed -i 's/TIMESTAMP_HERE/" + formatted_time + "/g' /tmp/index.html"
os.system(the_command)
the_command = "sed -i 's/NUMBER_OF_REPORTING_SYSTEMS/" + str(number_of_fog_systems) + "/g' /tmp/index.html"
os.system(the_command)




# Upload the index.html file to base and archived..
s3_client.upload_file("/tmp/index.html", settings["s3_bucket_name"], "archive/" + formatted_time + "/index.html", ExtraArgs={'ContentType': "text/html"})
s3_client.upload_file("/tmp/index.html", settings["s3_bucket_name"], "index.html", ExtraArgs={'ContentType': "text/html"})


