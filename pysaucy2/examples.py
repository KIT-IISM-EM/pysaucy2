"""
Some example graphs or graph generators.

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from __future__ import absolute_import, unicode_literals

from .graph import Graph


def butterfly():
    """
    The butterfly graph which consists of 5 nodes and 6 edges:
    Two complete graphs with 3 nodes are merged by sharing
    one of the nodes each.

    :return: Butterfly graph
    """
    return Graph([[1, 2], [2], [3, 4], [4], []])


def karate():
    """
    The Zachary karate network (n=34, m=78) with :math:`\left|Aut(G)\\right| = 480`

    :return: Karate graph
    """
    return Graph([
        [31, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 17, 19, 21],
        [2, 3, 7, 13, 17, 19, 21, 30],
        [3, 32, 7, 8, 9, 13, 27, 28],
        [7, 12, 13],
        [10, 6],
        [6, 10, 16],
        [16],
        [],
        [30, 33, 32],
        [33],
        [],
        [],
        [],
        [33],
        [32, 33],
        [32, 33],
        [],
        [],
        [32, 33],
        [33],
        [32, 33],
        [],
        [32, 33],
        [32, 25, 27, 33, 29],
        [31, 25, 27],
        [31],
        [33, 29],
        [33],
        [31, 33],
        [32, 33],
        [33, 32],
        [32, 33],
        [33],
        []])


def complete(n):
    """
    Create an undirected complete graph of *n* nodes.

    :param n: Number of nodes
    :return: A complete graph
    """
    return Graph([list(range(i + 1, n)) for i in range(n)])
