===============================================================
 pyre2: Python RE2 wrapper for linear-time regular expressions
===============================================================

.. image:: https://github.com/andreasvc/pyre2/workflows/Build/badge.svg
    :target: https://github.com/andreasvc/pyre2/actions?query=workflow:Build
    :alt: Build CI Status

.. image:: https://github.com/andreasvc/pyre2/workflows/Release/badge.svg
    :target: https://github.com/andreasvc/pyre2/actions?query=workflow:Release
    :alt: Release CI Status

.. image:: https://img.shields.io/github/v/tag/andreasvc/pyre2?color=green&include_prereleases&label=latest%20release
    :target: https://github.com/andreasvc/pyre2/releases
    :alt: GitHub tag (latest SemVer, including pre-release)

.. image:: https://badge.fury.io/py/pyre2.svg
   :target: https://badge.fury.io/py/pyre2
    :alt: Pypi version

.. image:: https://github.com/andreasvc/pyre2/actions/workflows/conda-dev.yml/badge.svg
    :target: https://github.com/andreasvc/pyre2/actions/workflows/conda-dev.yml
    :alt: Conda CI Status

.. image:: https://img.shields.io/github/license/andreasvc/pyre2
    :target: https://github.com/andreasvc/pyre2/blob/master/LICENSE
    :alt: License

.. image:: https://img.shields.io/badge/python-3.6+-blue.svg
    :target: https://www.python.org/downloads/
    :alt: Python version

.. image:: https://anaconda.org/conda-forge/pyre2/badges/version.svg
   :target: https://anaconda.org/conda-forge/pyre2
   :alt: version

.. image:: https://anaconda.org/conda-forge/pyre2/badges/platforms.svg
   :target: https://anaconda.org/conda-forge/pyre2
   :alt: platforms

.. image:: https://anaconda.org/conda-forge/pyre2/badges/downloads.svg
   :target: https://anaconda.org/conda-forge/pyre2
   :alt: downloads


.. contents:: Table of Contents
   :depth: 2
   :backlinks: top


Summary
=======

pyre2 is a Python extension that wraps
`Google's RE2 regular expression library <https://github.com/google/re2>`_.
The RE2 engine compiles (strictly) regular expressions to
deterministic finite automata, which guarantees linear-time behavior.

Intended as a drop-in replacement for ``re``. Unicode is supported by encoding
to UTF-8, and bytes strings are treated as UTF-8 when the UNICODE flag is given.
For best performance, work with UTF-8 encoded bytes strings.

Installation
============

Normal usage for Linux/Mac/Windows::

  $ pip install pyre2

Compiling from source
---------------------

Requirements for building the C++ extension from the repo source:

* A build environment with ``gcc`` or ``clang`` (e.g. ``sudo apt-get install build-essential``)
* Build tools and libraries: RE2, pybind11, and cmake installed in the build
  environment.

  + On Ubuntu/Debian: ``sudo apt-get install build-essential cmake ninja-build python3-dev cython3 pybind11-dev libre2-dev``
  + On Gentoo, install dev-util/cmake, dev-python/pybind11, and dev-libs/re2
  + For a venv you can install the pybind11, cmake, and cython packages from PyPI

On MacOS, use the ``brew`` package manager::

  $ brew install -s re2 pybind11

On Windows use the ``vcpkg`` package manager::

  $ vcpkg install re2:x64-windows pybind11:x64-windows

You can pass some cmake environment variables to alter the build type or
pass a toolchain file (the latter is required on Windows) or specify the
cmake generator.  For example::

  $ CMAKE_GENERATOR="Unix Makefiles" CMAKE_TOOLCHAIN_FILE=clang_toolchain.cmake tox -e deploy

For development, get the source::

    $ git clone git://github.com/andreasvc/pyre2.git
    $ cd pyre2
    $ make

This builds a wheel in ``dist/`` using the active ``python3`` interpreter.
Build dependencies from ``pyproject.toml`` are installed in an isolated build
environment, so they do not need to be installed manually. The RE2 library and
compiler toolchain are system dependencies and must still be installed as
described above.

To compile and install pyre2 into the active Python environment instead::

    $ make install

Using a virtual environment is recommended. You can select a specific Python
interpreter by overriding ``PYTHON``, for example::

    $ PYTHON=python3.12 make

The equivalent commands without ``make`` are::

    $ python3 -m pip wheel --no-deps --wheel-dir dist .
    $ python3 -m pip install .

To install the test dependencies and run the test suite with the selected
interpreter::

    $ make test
    $ PYTHON=python3.15 make test

Use ``make clean`` to remove compiled extension and intermediate build files.
Use ``make distclean`` to also remove distributions, tox environments, and
pytest caches.


Platform-agnostic building with conda
-------------------------------------

An alternative to the above is provided via the `conda`_ recipe (use the
`miniconda installer`_ if you don't have ``conda`` installed already).


.. _conda: https://anaconda.org/conda-forge/pyre2
.. _miniconda installer: https://docs.conda.io/en/latest/miniconda.html

Documentation
=============

Consult the documentation

- online: http://andreasvc.github.io/pyre2/
- interactively through ipython or ``pydoc re2`` etc.
- in the source code as docstrings.

Backwards Compatibility
=======================

The stated goal of this module is to be a drop-in replacement for ``re``, i.e.::

    try:
        import re2 as re
    except ImportError:
        import re

That being said, there are features of the ``re`` module that this module may
never have; these will be handled through fallback to the original ``re`` module:

* lookahead assertions ``(?!...)``
* backreferences, e.g., ``\\1`` in search pattern
* possessive quantifiers ``*+, ++, ?+, {m,n}+``
* atomic groups ``(?>...)``
* ``\W`` and ``\S`` not supported inside character classes

On the other hand, unicode character classes are supported (e.g., ``\p{Greek}``).
Syntax reference: https://github.com/google/re2/wiki/Syntax

The ``re.Scanner`` helper is outside the scope of pyre2. Code that needs it
should import it directly from Python's standard-library ``re`` module::

    from re import Scanner

However, there are times when you may want to be notified of a failover. The
function ``set_fallback_notification`` determines the behavior in these cases::

    try:
        import re2 as re
    except ImportError:
        import re
    else:
        re.set_fallback_notification(re.FALLBACK_WARNING)

``set_fallback_notification`` takes three values:
``re.FALLBACK_QUIETLY`` (default), ``re.FALLBACK_WARNING`` (raise a warning),
and ``re.FALLBACK_EXCEPTION`` (raise an exception).

You might also change the fallback module from ``re`` (default) to something
else, like ``regex``. You can achieve that with the function
``set_fallback_module``::

    >>> import re2
    >>> re2.set_fallback_notification(re2.FALLBACK_WARNING)
    >>> type(re2.compile(r"foo"))
    <class 're2.Pattern'>
    >>> type(re2.compile(r"foo(?!bar)"))
    <stdin>:1: UserWarning: WARNING: Using re module. Reason: invalid perl operator: (?!
    <class 're2.FallbackPattern'>
    >>> import regex
    >>> re2.set_fallback_module(regex)
    >>> type(re2.compile(r"foo(?!bar)"))
    <stdin>:1: UserWarning: WARNING: Using regex module. Reason: invalid perl operator: (?!
    <class 're2.FallbackPattern'>

Unicode Support
===============

Python ``bytes`` and ``unicode`` strings are fully supported, but note that
``RE2`` works with UTF-8 encoded strings under the hood, which means that
``unicode`` strings need to be encoded and decoded back and forth.
There are two important factors:

* whether a ``unicode`` pattern and search string is used (will be encoded to UTF-8 internally)
* the ``UNICODE`` flag: whether operators such as ``\w`` recognize Unicode characters.

To avoid the overhead of encoding and decoding to UTF-8, it is possible to pass
UTF-8 encoded bytes strings directly but still treat them as ``unicode``::

    In [18]: re2.findall(u'\w'.encode('utf8'), u'Mötley Crüe'.encode('utf8'), flags=re2.UNICODE)
    Out[18]: ['M', '\xc3\xb6', 't', 'l', 'e', 'y', 'C', 'r', '\xc3\xbc', 'e']
    In [19]: re2.findall(u'\w'.encode('utf8'), u'Mötley Crüe'.encode('utf8'))
    Out[19]: ['M', 't', 'l', 'e', 'y', 'C', 'r', 'e']

However, note that the indices in ``Match`` objects will refer to the bytes string.
The indices of the match in the ``unicode`` string could be computed by
decoding/encoding, but this is done automatically and more efficiently if you
pass the ``unicode`` string::

    >>> re2.search(u'ü'.encode('utf8'), u'Mötley Crüe'.encode('utf8'), flags=re2.UNICODE)
    <re2.Match object; span=(10, 12), match='\xc3\xbc'>
    >>> re2.search(u'ü', u'Mötley Crüe', flags=re2.UNICODE)
    <re2.Match object; span=(9, 10), match=u'\xfc'>

Finally, if you want to match bytes without regard for Unicode characters,
pass bytes strings and leave out the ``UNICODE`` flag (this will cause Latin 1
encoding to be used with ``RE2`` under the hood)::

    >>> re2.findall(br'.', b'\x80\x81\x82')
    ['\x80', '\x81', '\x82']

Performance
===========

Performance is of course the point of this module, so it better perform well.
Regular expressions vary widely in complexity, and the salient feature of ``RE2`` is
that it behaves well asymptotically. This being said, for very simple substitutions,
I've found that occasionally python's regular ``re`` module is actually slightly faster.
However, when the ``re`` module gets slow, it gets *really* slow, while this module
buzzes along.

The example below runs against 5 MB of Wikipedia XML data. Each operation is
run multiple times with ``timeit``. These results were generated with Python
3.13.5 and GCC 14.2.0; relative performance depends on the pattern, Python and
RE2 versions, compiler, and hardware. To reproduce the results, see the
`performance script <https://github.com/andreasvc/pyre2/blob/master/tests/performance.py>`_.

+-----------------+-----------------------------------------------------------+------------+--------------+---------------+-------------+-----------------+----------------+
|Test             |Description                                                |# total runs|``re`` time(s)|``re2`` time(s)|% ``re`` time|``regex`` time(s)|% ``regex`` time|
+=================+===========================================================+============+==============+===============+=============+=================+================+
|Findall URI/Email|Find URIs and emails                                       |2           |4.950         |0.049          |0.99%        |7.641            |0.64%           |
+-----------------+-----------------------------------------------------------+------------+--------------+---------------+-------------+-----------------+----------------+
|Replace WikiLinks|Replace links of the form [[Obama|Barack_Obama]] with Obama|100         |4.621         |4.206          |91.03%       |5.018            |83.81%          |
+-----------------+-----------------------------------------------------------+------------+--------------+---------------+-------------+-----------------+----------------+
|Remove WikiLinks |Remove links of the form [[Obama|Barack_Obama]]            |100         |2.141         |3.940          |184.06%      |2.320            |169.85%         |
+-----------------+-----------------------------------------------------------+------------+--------------+---------------+-------------+-----------------+----------------+
|Split pages      |Split the data by the <page> tag                           |100         |0.472         |0.148          |31.39%       |0.623            |23.77%          |
+-----------------+-----------------------------------------------------------+------------+--------------+---------------+-------------+-----------------+----------------+

Feel free to add more speed tests to the bottom of the script and send a pull request my way!

Current Status
==============

The tests show the following differences with Python's ``re`` module:

* The ``$`` operator in Python's ``re`` matches twice if the string ends
  with ``\n``. This can be simulated using ``\n?$``, except when doing
  substitutions.
* The ``pyre2`` module and Python's ``re`` may behave differently with nested groups.
  See ``tests/test_emptygroups.txt`` for the examples.

Please report any further issues with ``pyre2``.

Tests
=====

If you would like to help, one thing that would be very useful
is writing comprehensive tests for this. It's actually really easy:

* Come up with regular expression problems using the regular python 're' module.
* Write a session in python traceback format `Example <http://github.com/andreasvc/pyre2/blob/master/tests/test_search.txt>`_.
* Replace your ``import re`` with ``import re2 as re``.
* Save it with as ``test_<name>.txt`` in the tests directory. You can comment on it however you like and indent the code with 4 spaces.


Credits
=======
This code builds on the following projects (in chronological order):

- Google's RE2 regular expression library: https://github.com/google/re2
- Facebook's pyre2 github repository: http://github.com/facebook/pyre2/
- Mike Axiak's Cython version of this: http://github.com/axiak/pyre2/ (seems not actively maintained)
- This fork adds Python 3 support and other improvements.
