"""

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from __future__ import absolute_import

from .graph import Graph
from . import examples


def run_saucy(g, colors=None, on_automorphism=None):
    """
    Make the saucy call.

    .. warning::
       Using the *on_automorphism* callback is quite expensive and will slow down the algorithm
       significantly if many generators are found.

    The automorphism group size is defined by *group size base* :math:`b` and
    *group size exponent* :math:`e` as :math:`b\cdot10^e`.

    The returned *orbits* are a list of orbit ids where ``orbits[i]`` is some (integer) orbit id
    and all nodes on the same orbit have the same id.

    :param g: The graph
    :type g: `pysaucy2.graph.Graph`
    :param colors: (Optional) A partition of node colors of length :math:`n`
    :param on_automorphism: An optional callback function with signature (graph, permutation, support)
    :return: (group size base, group size exponent, levels, nodes, bads, number of generators, support, orbits)
    """
    if colors is not None:
        g.colors = colors
    return g.run_saucy(on_automorphism)

__all__ = ['Graph', 'run_saucy', 'examples']
