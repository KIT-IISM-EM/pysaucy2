Installation
============

Installation follows the standard procedure (:py:mod:`setuptools` required):
 1) Obtain the source package of pysaucy2 and extract the archive
 2) Obtain the source code of saucy_ (available only on request from the authors) and extract to ``saucy``
 3) Run ``python setup.py install`` for installation. :py:mod:`setuptools` will take care of properly building
    the C sources and installing the package afterwards.


.. hint::
   If an error occurs, read the description carefully. Often, missing header files (e.g. from Python) are a
   cause for the error. If e.g. ``saucy.h`` cannot be found, make sure saucy's sources are not located in
   some deeper subdirectory.

.. note::
   Installation utilizing :py:mod:`pip` should also work, but without guarantee.


Running Basic Tests
-------------------

Pysaucy2 provides some basic tests, which all should succeed. To run them, call ``python setup.py test``
(:py:mod:`nose` is required).


.. _saucy: http://vlsicad.eecs.umich.edu/BK/SAUCY/#source