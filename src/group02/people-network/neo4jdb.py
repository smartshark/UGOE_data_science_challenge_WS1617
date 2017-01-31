from config import config
from py2neo import authenticate, Graph

authenticate(config.get('neo4j','host'), config.get('neo4j','username'), config.get('neo4j','password'))

graph = Graph()