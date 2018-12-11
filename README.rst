pysaucy
=======
A Python binding for the saucy algorithm for the graph automorphism problem.
This package is written in Cython and supersedes https://github.com/KIT-IISM-EM/pysaucy,
which is written in plain C.

Other differences:
  - Slightly different API, but downward compatibility is mostly preserved
  - This package also works correctly with directed graphs (in pysaucy this feature is broken)
  - pysaucy2 works with Python2 and Python3 (tested with 2.7.15 and 3.6.5)

Install
-------
To install, run ``python setup.py install`` and ensure the source code of
`Saucy <http://vlsicad.eecs.umich.edu/BK/SAUCY/>`_ is found in the
path ``./saucy``.
The source code is available from the authors on request.

Tests
-----
Run the tests with ``python setup.py test``

Documentation
-------------
The documentation can be found under https://KIT-IISM-EM.github.io/pysaucy2/html/

Changes
-------

0.3.1b1
  - Improved performance
  - Better documentation and minimal quickstart example
  
0.3b1
  - Improved (i.e. faster) orbit partition computation
  - Added more tests
  - Better documentation

0.2b1
  - First public version
  - Includes all features of pysaucy
