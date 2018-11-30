"""

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from cpython.ref cimport PyObject

cdef extern from 'saucy.h':
    ctypedef int saucy_consumer(int, const int *, int, int *, void *)

    struct saucy:
        pass

    struct saucy_stats:
        double grpsize_base
        int grpsize_exp
        int levels
        int nodes
        int bads
        int gens
        int support

    struct saucy_graph:
        int n
        int e
        int *adj
        int *edg

    saucy *saucy_alloc(int n)

    void saucy_search(saucy *s, const saucy_graph *graph, int directed, const int *colors, saucy_consumer *consumer, void *arg, saucy_stats *stats) except *

    void saucy_free(saucy *s)

cdef struct saucy_data:
    PyObject *py_callback
    PyObject *py_graph
    int *partial_orbit_partition