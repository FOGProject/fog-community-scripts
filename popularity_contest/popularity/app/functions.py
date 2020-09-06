from app import app
import json
import MySQLdb as mysql
from flask import jsonify, request
import datetime


settingsFilePath = '/opt/popularity/settings.json'
with open(settingsFilePath, 'r') as settings_file:
    settings = json.loads(settings_file.read())
for key in settings.keys():
    app.config[key] = settings[key]

# Connect to database.
db = mysql.connect(host=settings['MYSQL_HOST'],user=settings['MYSQL_USER'],passwd=settings['MYSQL_PASSWORD'], db=settings['MYSQL_DB'], port=settings['MYSQL_PORT'])


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

