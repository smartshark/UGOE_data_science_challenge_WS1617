from config import config
from pymongo import MongoClient

client = MongoClient(config.get('mongodb','uri') + '/' + config.get('mongodb','database'))
db = client[config.get('mongodb','database')]
