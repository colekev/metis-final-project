from flask import Flask
from flask import render_template
from pymongo import MongoClient
import json
from bson import json_util
from bson.json_util import dumps

app = Flask(__name__)

MONGODB_HOST = 'localhost'
MONGODB_PORT = 27017
DBS_NAME = 'flask'
COLLECTION_NAME = 'sentiment_date'
FIELDS = {'NA': False, '_id': False,}

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/player-tweets/all")
def all():
    connection = MongoClient(MONGODB_HOST, MONGODB_PORT)
    collection = connection[DBS_NAME][COLLECTION_NAME]
    projects = collection.find(projection=FIELDS)
    json_projects = []
    for project in projects:
        json_projects.append(project)
    json_projects = json.dumps(json_projects, default=json_util.default)
    connection.close()
    return json_projects

FIELDS_NAMES = {'_id': False, 'player': True}

@app.route("/player-tweets/names")
def player_names():
    connection = MongoClient(MONGODB_HOST, MONGODB_PORT)
    collection = connection[DBS_NAME][COLLECTION_NAME]
    player_names = collection.find(projection=FIELDS_NAMES, limit=5000)
    names = []
    for name in player_names:
        names.append(name)
    names = json.dumps(names, default=json_util.default)
    connection.close()
    return names

if __name__ == "__main__":
    app.run(host='0.0.0.0',port=5000,debug=True)
