
Welcome to pysaucy2's documentation!
====================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   about
   installation
   modules

Quickstart
==========
Install the package, then open your favorite python console:

.. code-block:: python
   :linenos:

   from pysaucy2 import examples

   b = examples.butterfly()
   b.to_edge_lists()
   # [[1, 2], [2], [3, 4], [4], []] <- This means: Node 0 is connected to nodes 1 and 2, node 1 to node 2, ...
   b.run_saucy()
   # (8.0, 0, 3, 7, 0, 2, 6)
   # -> |Aut(G)| = 8.0 * 10**0
   # -> The search tree has depth 3
   # -> 7 tree nodes were explored
   # -> 0 'bads' (i.e. no backtracking was performed)
   # -> 2 generators for Aut(G) were found
   # -> The total support of these to generators is 6

   def cb(graph, perm, supp):
      print(list(perm))

   b.run_saucy(cb)
   # [1, 0, 2, 3, 4] <- The first generator is p = (0 1)
   # [4, 3, 2, 1, 0] <- The second generator is q = (0 4)(1 3)
   # (8.0, 0, 3, 7, 0, 2, 6) <- As above (2 generators -> True, total support 6 = 2 + 4 -> True)



Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
