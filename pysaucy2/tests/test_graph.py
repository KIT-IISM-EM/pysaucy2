"""

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from __future__ import absolute_import

import collections
from unittest import TestCase

import pysaucy2


class TestGraph(TestCase):

    def setUp(self):
        self.k1000 = pysaucy2.examples.complete(1000)

    def test_k1000(self):
        result = pysaucy2.run_saucy(self.k1000)
        self.assertTupleEqual(result, (4.023872600770939, 2567, 1000, 3995, 0, 999, 1998))

    def test_k10(self):
        k10 = pysaucy2.examples.complete(10)
        result = pysaucy2.run_saucy(k10)
        self.assertTupleEqual(result, (3.6287999999999996, 6, 10, 35, 0, 9, 18))

    def test_empty_k10(self):
        empty = pysaucy2.Graph([[]]*10)
        result = pysaucy2.run_saucy(empty)
        self.assertTupleEqual(tuple(list(result)[:7]), (3.6287999999999996, 6, 10, 35, 0, 9, 18))

    def test_null_graph(self):
        with self.assertRaises(ValueError) as e:
            pysaucy2.Graph([])

        self.assertIn('The graph without nodes is not allowed', str(e.exception))

    def test_wrong_parameters(self):
        with self.assertRaises(TypeError) as e:
            pysaucy2.Graph([1])

        self.assertIn('object of type \'int\' has no len()', str(e.exception))

        with self.assertRaises(TypeError) as e:
            pysaucy2.Graph([["1", 2, 3], [""]])

        with self.assertRaises(ValueError) as e:
            pysaucy2.Graph([[1, 2, 3], []])

        with self.assertRaises(OverflowError) as e:
            pysaucy2.Graph([[2**31], []])

        with self.assertRaises(ValueError):
            pysaucy2.Graph([[2 ** 31 - 1], []])

    def test_loops(self):
        # Loop, no automorphisms
        g1 = pysaucy2.Graph([[0, 1], []])
        result = pysaucy2.run_saucy(g1)
        self.assertEqual(result, (1.0, 0, 1, 1, 0, 0, 0))
        self.assertEqual(g1.orbits, [0, 1])

        # No loop, automorphisms
        g2 = pysaucy2.Graph([[1], []])
        result = pysaucy2.run_saucy(g2)
        self.assertEqual(result, (2.0, 0, 2, 3, 0, 1, 2))
        self.assertEqual(g2.orbits, [0, 0])

        # Loops, automorphisms
        g3 = pysaucy2.Graph([[0, 1], [1]])
        result = pysaucy2.run_saucy(g3)
        self.assertEqual(result, (2.0, 0, 2, 3, 0, 1, 2))
        self.assertEqual(g3.orbits, [0, 0])

    def test_directed_graphs(self):
        # Directed butterfly (interpret the undirected edges as directed
        edges = pysaucy2.examples.butterfly().to_edge_lists()
        dir_butterfly = pysaucy2.Graph(edges, directed=True)

        result = pysaucy2.run_saucy(dir_butterfly)

        self.assertTupleEqual(result, (1.0, 0, 1, 1, 0, 0, 0))

        g1 = pysaucy2.Graph([[1], []])
        res1 = g1.run_saucy()
        g2 = pysaucy2.Graph([[1], [0]], directed=True)
        res2 = g2.run_saucy()
        self.assertTupleEqual(res1, res2)

    def test_color_partition(self):
        k11 = pysaucy2.examples.complete(11)
        colors = [0]*11
        colors[10] = 1
        # colors 'fixes' one node by putting it into another partition
        # => Aut(k11, colors) ~ Aut(k10)
        result = pysaucy2.run_saucy(k11, colors=colors)
        self.assertTupleEqual(tuple(list(result)), (3.6287999999999996, 6, 10, 35, 0, 9, 18))

    def test_karate(self):
        karate = pysaucy2.examples.karate()
        result = pysaucy2.run_saucy(karate)
        self.assertEqual(480, result[0] * 10**result[1])
        orbit_sizes = collections.defaultdict(int)
        for orbit_id in karate.orbits:
            orbit_sizes[orbit_id] += 1
        self.assertEqual(len(orbit_sizes), 27)

    def test_butterfly(self):
        butterfly = pysaucy2.examples.butterfly()
        result = pysaucy2.run_saucy(butterfly)
        self.assertListEqual([0, 0, 2, 0, 0], butterfly.orbits)

    def test_on_automorphism_callback(self):
        karate = pysaucy2.examples.karate()
        generators = []

        def on_aut(graph, perm, supp):
            generators.append(perm)

        result = pysaucy2.run_saucy(karate, on_automorphism=on_aut)

        self.assertEqual(result[5], len(generators))

        # Too few parameters
        def invalid_callback_1(a, b):
            pass

        with self.assertRaises(TypeError):
            pysaucy2.run_saucy(karate, on_automorphism=invalid_callback_1)

        # No parameters
        def invalid_callback_2():
            pass

        with self.assertRaises(TypeError):
            pysaucy2.run_saucy(karate, on_automorphism=invalid_callback_2)

        # Too many parameters
        def invalid_callback_3(a, b, c, d):
            pass

        with self.assertRaises(TypeError):
            pysaucy2.run_saucy(karate, on_automorphism=invalid_callback_3)

