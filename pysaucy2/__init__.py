"""

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from __future__ import absolute_import

from .graph import Graph
from . import examples


def run_saucy(g, colors=None, on_automorphism=None):
    """
    Make the saucy call. This function is kept for backward compatibility to pysaucy.
    You may want to directly call :meth:`pysaucy2.graph.Graph.run_saucy`.
    """
    if colors is not None:
        g.colors = colors
    return g.run_saucy(on_automorphism)

__all__ = ['Graph', 'run_saucy', 'examples']
