"""

.. moduleauthor:: Fabian Ball <fabian.ball@kit.edu>
"""
from __future__ import absolute_import

from unittest import TestCase

import pysaucy2


class TestDatastructures(TestCase):
    def test_IntArray_success(self):
        ia = pysaucy2.datastructures.IntArray(range(10))
        self.assertEqual(len(ia), 10)
        for i in range(10):
            self.assertEqual(ia[i], i)

        self.assertEqual(len(pysaucy2.datastructures.IntArray()), 0)

    def test_IntArray_wrong_type(self):
        with self.assertRaises(TypeError):
            pysaucy2.datastructures.IntArray([1, 2, '3'])

        # Implicit type conversion... We can live with that
        ia = pysaucy2.datastructures.IntArray([1.1, 2])
        self.assertEqual(ia[0], 1)

    def test_IntArray_assignment(self):
        ia = pysaucy2.datastructures.IntArray([1, 2])

        with self.assertRaises(TypeError):
            ia[0] = 2

        with self.assertRaises(TypeError):
            del ia[1]
