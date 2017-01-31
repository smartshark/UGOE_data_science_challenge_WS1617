from IPython.display import IFrame
import json
import uuid
from neo4jdb import graph


def vis_network(nodes, edges, physics=False):
    html = """
    <html>
    <head>
      <script type="text/javascript" src="lib/vis/dist/vis.js"></script>
      <link href="lib/vis/dist/vis.css" rel="stylesheet" type="text/css">
    </head>
    <body>

    <div id="{id}"></div>

    <script type="text/javascript">
      var nodes = {nodes};
      var edges = {edges};

      var container = document.getElementById("{id}");

      var data = {{
        nodes: nodes,
        edges: edges
      }};

      var options = {{
          nodes: {{
              shape: 'dot',
              size: 15,
              font: {{
                  size: 10
              }}
          }},
          edges: {{
              font: {{
                  size: 6,
                  align: 'middle'
              }},
              color: 'gray',
              arrows: {{
                  to: {{enabled: true, scaleFactor: 0.2}}
              }},
              smooth: {{enabled: false}}
          }},
          physics: {{
              enabled: {physics}
          }}
      }};

      var network = new vis.Network(container, data, options);

    </script>
    </body>
    </html>
    """

    unique_id = str(uuid.uuid4())
    html = html.format(id=unique_id, nodes=json.dumps(nodes), edges=json.dumps(edges), physics=json.dumps(physics))

    filename = "figure/graph-physics-{}.html".format(physics)

    file = open(filename, "w")
    file.write(html)
    file.close()

    return IFrame(filename, width="100%", height="400")


def draw(graph, options, physics=False, limit=10000):
    # The options argument should be a dictionary of node labels and property keys; it determines which property
    # is displayed for the node label. For example, in the movie graph, options = {"Movie": "title", "Person": "name"}.
    # Omitting a node label from the options dict will leave the node unlabeled in the visualization.
    # Setting physics = True makes the nodes bounce around when you touch them!
    # Exepted Users:
    # 	5854143f926fbea6a4f94cf9 some script username
    # 	user@zookeeper.apache.org
    # 	dev@zookeeper.apache.org
    # 	zookeeper-user@hadoop.apache.org
    # 	zookeeper-dev@hadoop.apache.org

    query = """
    MATCH (n)
    WHERE
       n.person_id <> '5854143f926fbea6a4f94cf9' and
       n.email <> 'user@zookeeper.apache.org' and
       n.email <> 'dev@zookeeper.apache.org' and
       n.email <> 'zookeeper-user@hadoop.apache.org' and
       n.email <> 'zookeeper-dev@hadoop.apache.org'
    WITH n
    LIMIT { limit }
    OPTIONAL MATCH (n)-[r]->(m)
    WHERE
       m.person_id <> '5854143f926fbea6a4f94cf9' and
       m.email <> 'user@zookeeper.apache.org' and
       m.email <> 'dev@zookeeper.apache.org' and
       m.email <> 'zookeeper-user@hadoop.apache.org' and
       m.email <> 'zookeeper-dev@hadoop.apache.org'
    RETURN n AS source_node,
           id(n) AS source_id,
           r,
           m AS target_node,
           id(m) AS target_id
    """

    data = graph.run(query, limit=limit)

    nodes = []
    edges = []

    def get_vis_info(node, id):
        node_label = list(node.labels())[0]
        prop_key = options.get(node_label)
        vis_label = node.properties.get(prop_key, "")

        return {"id": id, "label": vis_label, "group": node_label, "title": repr(node.properties)}

    for row in data:
        source_node = row[0]
        source_id = row[1]
        rel = row[2]
        target_node = row[3]
        target_id = row[4]

        source_info = get_vis_info(source_node, source_id)

        if source_info not in nodes:
            nodes.append(source_info)

        if rel is not None:
            target_info = get_vis_info(target_node, target_id)

            if target_info not in nodes:
                nodes.append(target_info)

            edges.append({"from": source_info["id"], "to": target_info["id"], "label": ""})

    return vis_network(nodes, edges, physics=physics)


if __name__ == "__main__":
    draw(graph, {"Person": "name"}, physics=False)
    draw(graph, {"Person": "name"}, physics=True)