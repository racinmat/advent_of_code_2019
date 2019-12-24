import networkx as nx
import numpy as np
import string

A1 = np.array([
    [0, 16, 14, 9, 11, 16, 5, 11],
    [16, 0, 16, 11, 9, 14, 11, 5],
    [14, 16, 0, 5, 11, 16, 9, 11],
    [9, 11, 5, 0, 6, 11, 4, 6],
    [11, 9, 11, 6, 0, 5, 6, 4],
    [16, 14, 16, 11, 5, 0, 11, 9],
    [5, 11, 9, 4, 6, 11, 0, 6],
    [11, 5, 11, 6, 4, 9, 6, 0],
])
A2 = np.array([
    [0, 16, 14, 11, 16, 11],
    [16, 0, 16, 9, 14, 5],
    [14, 16, 0, 11, 16, 11],
    [11, 9, 11, 0, 5, 4],
    [16, 14, 16, 5, 0, 9],
    [11, 5, 11, 4, 9, 0],
])

A = A1
A = A.astype(np.float)

G = nx.from_numpy_matrix(A)
G = nx.relabel_nodes(G, dict(zip(range(len(G.nodes())), string.ascii_uppercase)))

G = nx.drawing.nx_agraph.to_agraph(G)

G.node_attr.update(color="red", style="filled")
G.edge_attr.update(color="blue", width="2.0")

G.draw('./dists-after-f.png', format='png', prog='neato')
