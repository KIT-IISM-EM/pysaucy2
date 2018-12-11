import sys

from setuptools import setup, Extension
from Cython.Build import cythonize

ext = [
    Extension('pysaucy2.graph',
              sources=['pysaucy2/graph.pyx', 'saucy/saucy.c'],
              include_dirs=['pysaucy2', 'saucy'],
              extra_compile_args=[],
              language='c'),
    Extension('pysaucy2.datastructures',
              sources=['pysaucy2/datastructures.pyx'],
              include_dirs=['pysaucy2'],
              extra_compile_args=[],
              language='c'),
]

name = 'pysaucy2'
version = '0.3.1'
release = '0.3.1b1'
setup(
    name=name,
    version=version,
    packages=['pysaucy2'],
    url='https://github.com/KIT-IISM-EM/pysaucy2',
    license='MIT',
    author='Fabian Ball',
    author_email='fabian.ball@kit.edu',
    description='A Python binding for the saucy algorithm for the graph automorphism problem. Written in Cython.',
    install_requires=['Cython', 'future'],
    ext_modules=cythonize(ext, compiler_directives={'embedsignature': True,
                                                    'language_level': sys.version[0]}),
    test_suite='nose.collector',
    tests_require=['nose'],
    include_package_data=True,
    command_options={
            'build_sphinx': {
                'project': ('setup.py', name),
                'version': ('setup.py', version),
                'release': ('setup.py', release),
                'source_dir': ('setup.py', 'docs/source'),
                'builder': ('setup.py', 'html'),
                'build_dir': ('setup.py', 'docs'),
            }},
)
