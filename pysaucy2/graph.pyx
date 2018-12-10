"""

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from cpython.ref cimport PyObject
from libc.stdlib cimport malloc, calloc, free

from . cimport csaucy
from .datastructures cimport IntArray

import warnings


cdef class Graph:
    cdef:
        csaucy.saucy_graph* _graph
        bint _directed
        bint _running
        int* _colors
        int* _orbits

    def __init__(self, edge_lists, colors=None, directed=False):
        """
        Create a new graph.

        :param edge_lists:
        :type edge_lists: list
        :param colors: (Optional) A list of colors, one color for each node
        :type colors: list
        :param directed: (Optional) Determine that the graph is directed
        :type directed: boolean
        """
        pass

    def __cinit__(self, list edge_lists not None, list colors=None, bint directed=False):
        self._directed = directed
        self._running = False

        # Determine n from the data
        cdef int n = len(edge_lists)

        if n == 0:
            raise ValueError('The graph without nodes is not allowed')

        # Test for duplicate edges and count edges
        cdef int m = 0
        for n_id, edges in enumerate(edge_lists):
            if len(edges) != len(set(edges)):
                raise ValueError('There must not be any duplicate edges (multi-edges)')

            # The saucy graph data format expects m as a parameter -> this has only reasons for memory association
            # => Counting all (unique) edges is the same
            m += len(edges)

        # Init graph
        self._graph = <csaucy.saucy_graph*> malloc(sizeof(csaucy.saucy_graph))
        if self._graph is NULL:
            raise MemoryError()

        self._graph.adj = < int * > calloc((2 * n + 2 if directed else n + 1), sizeof(int))
        if self._graph.adj is NULL:
            raise MemoryError()

        self._graph.edg = < int * > malloc(2 * m * sizeof(int))
        if self._graph.edg is NULL:
            raise MemoryError()

        self._graph.n = n
        self._graph.e = m

        # Init colors
        self._colors = < int * > calloc(n, sizeof(int))

        if self._colors is NULL:
            raise MemoryError()

        if colors is not None:
            # Color set logic is encapsulated in the property setter
            # -> self.n MUST be accessible (i.e. self._graph.n must be set)!
            self.colors = colors

        # Index padding as replacement for C memory arithmetic
        cdef int pad_n = n+1 if directed else 0
        cdef int pad_m = m if directed else 0

        cdef int i, j
        # cdef int j
        # (1) Count outgoing and incoming edges for each node
        for i, adjacent_nodes in enumerate(edge_lists):
            self._graph.adj[i] += len(adjacent_nodes)  # Outgoing

            for j in adjacent_nodes:  # Type checking happens here implicitly
                # On the fly testing if the node ids have the correct format
                if j < 0 or j >= n:
                    raise ValueError('Node ids must not be between 0 and n-1')
                if not self._directed and j < i:
                    raise ValueError('Undirected edges (i,j) of node i must be encoded '
                                     'so that i <= j holds (i={}, j={})'.format(i, j))

                self._graph.adj[j+pad_n] += 1  # Incoming

        # (2) Cumulate the edge count -> correspond to indices in edg
        self._cumulate_values(0, self._graph.n)

        if self._directed:
            self._cumulate_values(self._graph.n + 1, 2 * self._graph.n + 1)

        # (3) Insert adjacencies
        for i, adjacent_nodes in enumerate(edge_lists):
            for j in adjacent_nodes:
                # Outgoing edge
                self._graph.edg[self._graph.adj[i]] = j
                self._graph.adj[i] += 1
                # Incoming edge
                # IMPORTANT: Use the index at j+pad_n and set the edge at position +pad_m
                self._graph.edg[self._graph.adj[j+pad_n]+pad_m] = i
                self._graph.adj[j+pad_n] += 1

        # (4) 'Rewind' the values if adj, which were shifted in (3)
        self._rewind_values()

    cdef _cumulate_values(self, int f, int l):
        cdef int i, s, t

        s = self._graph.adj[f]
        self._graph.adj[f] = 0

        for i in range(f+1, l + 1):
            t = self._graph.adj[i]
            self._graph.adj[i] = self._graph.adj[i-1] + s
            s = t

    cdef _rewind_values(self):
        cdef int i
        # Distinguish directed/undirected case
        if self._directed:
            # Outgoing edges
            for i in range(self._graph.n - 1, 0, -1):
                self._graph.adj[i] = self._graph.adj[i - 1]

            self._graph.adj[0] = 0
            self._graph.adj[self._graph.n] = self._graph.e

            # Incoming edges
            for i in range(2 * self._graph.n, self._graph.n+1, -1):
                self._graph.adj[i] = self._graph.adj[i - 1]

            self._graph.adj[self._graph.n+1] = 0
            self._graph.adj[2 * self._graph.n + 1] = self._graph.e
        else:
            for i in range(self._graph.n-1, 0, -1):
                self._graph.adj[i] = self._graph.adj[i - 1]

            self._graph.adj[0] = 0
            self._graph.adj[self._graph.n] = 2 * self._graph.e


    @staticmethod
    cdef int _on_automorphism(int n, const int *gamma, int k, int *support, void *arg) except * with gil:
        cdef csaucy.saucy_data *data = <csaucy.saucy_data *> arg

        Graph._update_orbits(data.partial_orbit_partition, n, gamma, k, support)

        cdef object py_callback = <object> data.py_callback

        if py_callback is not None:
            # This just works: If the callback has the wrong format, an exception is thrown and propagated to the user
            py_callback(<object>data.py_graph, IntArray.from_ptr(gamma, n), IntArray.from_ptr(support, k))

        return 1

    @staticmethod
    cdef void _update_orbits(int *partial_orbits, int n, const int *perm, int s, int *support) except *:
        cdef:
            int i, j, k, nid, oid, old_oid
            short *touched

        touched = <short *> calloc(n, sizeof(short))

        if touched is NULL:
            raise MemoryError()

        # for i in range(n):
        for i in range(s):  # Only iterate over the nodes in the support (expectation: s << n)
        # for nid in support[:s]:  # Only iterate over the nodes in the support (expectation: s << n)
            nid = support[i]
            # if perm[i] == i or touched[i]:  # i is fixed or the cycle which contains i was already visited
            if touched[nid]:  # i is fixed or the cycle which contains i was already visited
                continue
            else:
                # if partial_orbits[i] >= 0:  # Already colored
                if partial_orbits[nid] >= 0:  # Already colored
                    # oid = partial_orbits[i]
                    oid = partial_orbits[nid]
                else:
                    # oid = i
                    # partial_orbits[i] = oid
                    partial_orbits[nid] = oid = nid

                # touched[i] = True  # Set the current node as touched to prevent iterating over the cycle a 2nd time
                touched[nid] = True  # Set the current node as touched to prevent iterating over the cycle a 2nd time

                # j = perm[i]
                j = perm[nid]

                # while j != i:
                while j != nid:
                    if partial_orbits[j] < 0:  # Not colored yet
                        partial_orbits[j] = oid
                    elif partial_orbits[j] == oid:  # Already on the same orbit
                        pass
                    else:  # Already colored with another orbit id
                        old_oid = partial_orbits[j]
                        for k in range(n):  # Re-color the nodes which have the 'old' orbit id
                            if partial_orbits[k] == old_oid:
                                partial_orbits[k] = oid

                    touched[j] = True  # Set the current node as touched to prevent iterating over the cycle a 2nd time

                    j = perm[j]

        free(touched)

    cdef void _init_orbits(self) except *:
        if self._orbits is NULL:
            self._orbits = < int * > malloc(self._graph.n * sizeof(int))

        if self._orbits is NULL:
            raise MemoryError()

        cdef int i
        for i in range(self._graph.n):
            self._orbits[i] = -1

    cdef void _finalize_orbits(self):
        cdef:
            int i
            int* labels

        labels = <int *> malloc(self._graph.n * sizeof(int))
        if labels is NULL:
            raise MemoryError()

        for i in range(self._graph.n):
            labels[i] = -1

        for i in range(self._graph.n):
            if self._orbits[i] < 0:  # This happens only with trivial orbits
                self._orbits[i] = i
            else:
                if labels[self._orbits[i]] == -1:
                    labels[self._orbits[i]] = i

                self._orbits[i] = labels[self._orbits[i]]

        free(labels)

    @property
    def n(self):
        """
        :return: Number of nodes of the graph
        :rtype: int
        """
        return self._graph.n

    @property
    def m(self):
        """
        :return: Number of edges of the graph
        :rtype: int
        """
        return self._graph.e

    @property
    def directed(self):
        """
        Is the graph directed?

        :return: Directedness of the graph
        :rtype: boolean
        """
        return bool(self._directed)

    @property
    def adj(self):
        """
        Get the adjacency relations. These can only be interpreted in combination with ``edg``.
        The values of the list are index pointers regarding ``edg``.

        If the graph is undirected, the length is :math:`n+1`, else :math:`2n+2`.
        In the directed case, ``adj[i]`` (:math:`0 \leq i < n`) corresponds to the index in ``edg`` at which
        the outgoing edge relations of node :math:`i` begin.
        The last relation of this node is at position ``adj[i+1]-1``.
        The positions :math:`n+1 \leq i < 2n+2` correspond to the indices in ``edg`` that are the incoming edge
        relations (e.g. at ``adj[n+1+i]`` in ``edg`` is the first incoming edge that points towards node :math:`i`).
        If ``adj[i] == adj[i+1]`` node :math:`i` has no incoming/outgoing edges.

        In the undirected case, incoming and outgoing edges are 'the same'.
        Therefore, ``adj[i]`` is the index of the first edge incident to node :math:`i`.

        :return: A list of adjacency relations in the format that saucy needs
        :rtype: list
        """
        idx = 2*self._graph.n + 2 if self.directed else self._graph.n + 1
        return [i for i in self._graph.adj[:idx]]

    @property
    def edg(self):
        """
        Get the edge relations. These can only be interpreted in combination with ``adj``.
        See the detailed description at :meth:`graph.Graph.adj`.

        :return: A list of edge relations in the format that saucy needs
        :rtype: list
        """
        return [i for i in self._graph.edg[:2*self.m]]

    @property
    def colors(self):
        """
        Get the node colors.

        :return: A list of colors :math:`0 \leq c < n` for each node.
        :rtype: list
        """
        return [c for c in self._colors[:self.n]]

    @colors.setter
    def colors(self, list colors not None):
        """
        Set the node colors. This is not possible during a run of saucy.

        :param colors: A list of colors :math:`0 \leq c < n` for each node.
        :type colors: list
        """
        if self._running:
            warnings.warn('Can\'t change the colors during a running saucy search. '
                          'Did you try to call this function within the on_automorphism callback?')
            return

        n = self.n

        if len(colors) != n:
            raise ValueError('The provided colors must have lenth n={}'.format(n))

        if min(colors) < 0 or max(colors) >= n:
            raise ValueError('Colors must be in the range from 0 to {}'.format(n - 1))

        cdef int min_col = 0
        cdef int i, c
        for i, c in enumerate(colors):
            if c > i or c > min_col + 1:
                raise ValueError('Colors must be assigned in increasing order')
            elif c == min_col + 1:
                min_col += 1

            self._colors[i] = c

    @property
    def orbits(self):
        """
        Get the orbit partition as list of orbit ids.
        :return:
        :rtype: list
        """
        if self._orbits is NULL:
            warnings.warn('Orbits not yet available. Call run_saucy first.')
            return None
        else:
            return [i for i in self._orbits[:self._graph.n]]

    def to_edge_lists(self):
        """
        Convert this graph back to a list of adjacency lists.

        :return: Adjacency edge lists
        :rtype: list
        """
        edge_lists = [None for _ in range(self.n)]
        adj = self.adj
        edg = self.edg
        for i in range(self.n):
            if self.directed:
                edge_lists[i] = [j for j in edg[adj[i]:adj[i+1]]]
            else:
                edge_lists[i] = [j for j in edg[adj[i]:adj[i+1]] if j >= i]

        return edge_lists

    def run_saucy(self, on_automorphism=None):
        """
        Make the saucy call.

        .. warning::
           Using the *on_automorphism* callback is quite expensive and will slow down the algorithm
           significantly if many generators are found.

        The automorphism group size is defined by *group size base* :math:`b` and
        *group size exponent* :math:`e` as :math:`b\cdot10^e`.

        :param on_automorphism: An optional callback function with signature (graph, permutation, support)
        :return: (group size base, group size exponent, levels, nodes, bads, number of generators, support)
        """
        cdef:
            csaucy.saucy *s
            csaucy.saucy_graph *g
            csaucy.saucy_stats *stats
            csaucy.saucy_data *data

        if self._running:
            warnings.warn('The saucy search is already running! '
                          'Did you try to call this function within the on_automorphism callback?')
            return None

        g = self._graph
        s = csaucy.saucy_alloc(g.n)

        if s is NULL:
            raise MemoryError()

        stats = <csaucy.saucy_stats *> malloc(sizeof(csaucy.saucy_stats))

        if stats is NULL:
            csaucy.saucy_free(s)
            raise MemoryError()

        data = <csaucy.saucy_data *> malloc(sizeof(csaucy.saucy_data))

        if data is NULL:
            csaucy.saucy_free(s)
            free(stats)
            raise MemoryError()

        self._running = True  # Toggle the running state
        try:
            # This creates two C pointers, reference count is not increased
            # => Both Python objects are still referenced somewhere else, so no need to save a reference here
            # -> https://github.com/cython/cython/wiki/FAQ#what-is-the-difference-between-pyobject-and-object
            data.py_callback = <PyObject *> on_automorphism
            data.py_graph = <PyObject *> self

            # Save a local reference to the callback function (better be sure...)
            cb_ref = on_automorphism

            self._init_orbits()
            data.partial_orbit_partition = self._orbits
            csaucy.saucy_search(s, g, self._directed, self._colors, <csaucy.saucy_consumer *> self._on_automorphism, data, stats)
            self._finalize_orbits()
        except Exception as e:
            raise e
        else:
            # Convert to Python
            return stats.grpsize_base, stats.grpsize_exp, stats.levels, stats.nodes, stats.bads, stats.gens, stats.support
        finally:
            self._running = False  # Toggle the running state
            csaucy.saucy_free(s)
            free(data)
            free(stats)

    def __dealloc__(self):
        if self._colors is not NULL:
            free(self._colors)

        if self._orbits is not NULL:
            free(self._orbits)

        if self._graph is not NULL:
            if self._graph.adj is not NULL:
                free(self._graph.adj)
            if self._graph.edg is not NULL:
                free(self._graph.edg)

            free(self._graph)
