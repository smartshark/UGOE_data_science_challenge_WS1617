from neo4jdb import graph
from mongodb import db
from py2neo import Node, Relationship


def construct_db():
	graph.run("MATCH(n) DETACH DELETE n;")

	people = db.people

	for person in people.find():
		print(person)
		graph.create(Node("Person", person_id=str(person['_id']), name=person['name'], email=person['email']))


	messages = db.message

	for message in messages.find():
		try:
			message['from_id']
		except KeyError:
			pass
		else:
			node1 = graph.find_one("Person","person_id",str(message['from_id']))
			for id in message['to_ids']:
				node2 = graph.find_one("Person","person_id",str(id))
				print(node1['person_id'] + " -> " + node2['person_id'])
				graph.create(Relationship(node1, "TO", node2, weight=3))


if __name__ == "__main__":
	construct_db()