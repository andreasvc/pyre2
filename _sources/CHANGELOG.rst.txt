Changelog
=========


v0.3.6-29-g1465367
------------------

Changes
~~~~~~~
- Switch conda workflow to condadev environment. [Stephen Arnold]
- Swap out flake8 for cython-lint, update setup files, remove pep8 cfg.
  [Stephen Arnold]

Fixes
~~~~~
- Cleanup tests and fix a raw string test, enable more win32. [Stephen
  Arnold]

  * split all runners into separate arch via matrix
  * macos does need macos-14 to get a proper arm64 build
- Apply emptygroups fix and remove conda-only patch, also. [Stephen L
  Arnold]

  * release workflow: restrict pypi upload to repo owner
  * tox.ini: replace deprecated pep517 module, update deploy url

Other
~~~~~
- Fix #42. [Andreas van Cranenburgh]
- Include current notification level in cache key. [Andreas van
  Cranenburgh]

  this prevents a cached regular expression being used that was created
  with a different notification level.

  For example, the following now generates the expected warning::

      In [1]: import re2
      In [2]: re2.compile('a*+')
      Out[2]: re.compile('a*+')
      In [3]: re2.set_fallback_notification(re2.FALLBACK_WARNING)
      In [4]: re2.compile('a*+')
      <ipython-input-5-041122e221c7>:1: UserWarning: WARNING: Using re module. Reason: bad repetition operator: *+
        re2.compile('a*+')
      Out[4]: re.compile('a*+')
- Support fallback to Python re for possessive quantifiers. [Andreas van
  Cranenburgh]
- Document lack of support for possessive quantifiers and atomic groups.
  [Andreas van Cranenburgh]
- Make tests pass on my system; if this behavior turns out to be
  inconsistent across versions/platforms, maybe the test should be
  disabled altogether. #27. [Andreas van Cranenburgh]
- Add NOFLAGS and RegexFlags constants; #41. [Andreas van Cranenburgh]
- Remove python versions for make valgrind. [Andreas van Cranenburgh]
- Merge pull request #33 from sarnold/conda-patch. [Andreas van
  Cranenburgh]

  Conda patch for None vs empty string change
- Merge pull request #32 from JustAnotherArchivist/match-getitem.
  [Andreas van Cranenburgh]

  Make Match objects subscriptable
- Add test for Match subscripting. [JustAnotherArchivist]
- Make Match objects subscriptable. [JustAnotherArchivist]

  Fixes #31


v0.3.6 (2021-05-05)
-------------------
- Merge pull request #30 from sarnold/release-pr. [Andreas van
  Cranenburgh]

  workflow updates
- Add missing sdist job and artifact check to workflows, bump version.
  [Stephen L Arnold]
- Bump version again. [Andreas van Cranenburgh]
- Merge pull request #28 from sarnold/use-action. [Andreas van
  Cranenburgh]

  Workflow cleanup
- Move pypi upload to end of release.yml, use gitchangelog action.
  [Stephen L Arnold]


v0.3.4 (2021-04-10)
-------------------

Changes
~~~~~~~
- Ci: update workflows and tox cfg (use tox for smoke test) [Stephen L
  Arnold]
- Rename imported test helpers to avoid any discovery issues. [Stephen L
  Arnold]

Fixes
~~~~~
- Apply test patch, cleanup tox and pytest args. [Stephen L Arnold]
- Handle invalid escape sequence warnings, revert path changes. [Stephen
  L Arnold]

Other
~~~~~
- Bump version. [Andreas van Cranenburgh]
- Improve fix for #26. [Andreas van Cranenburgh]
- Add test for #26. [Andreas van Cranenburgh]
- Fix infinite loop on substitutions of empty matches; fixes #26.
  [Andreas van Cranenburgh]
- Fix "make test" and "make test2" [Andreas van Cranenburgh]
- Merge pull request #25 from sarnold/last-moves. [Andreas van
  Cranenburgh]

  Last moves
- Another one. [Andreas van Cranenburgh]
- Fix fix of conda patch. [Andreas van Cranenburgh]
- Fix conda patch. [Andreas van Cranenburgh]
- Fix "make test"; rename doctest files for autodetection. [Andreas van
  Cranenburgh]
- Fix narrow unicode detection. [Andreas van Cranenburgh]
- Merge pull request #24 from sarnold/tst-cleanup. [Andreas van
  Cranenburgh]

  Test cleanup
- Fix Python 2 compatibility. [Andreas van Cranenburgh]
- Use pytest; fixes #23. [Andreas van Cranenburgh]
- Tweak order of badges. [Andreas van Cranenburgh]
- Makefile: default to Python 3. [Andreas van Cranenburgh]
- Update README, fix Makefile. [Andreas van Cranenburgh]
- Merge pull request #22 from sarnold/missing-tests. [Andreas van
  Cranenburgh]

  add missing tests to sdist package, update readme and ci worflows (#1)
- Fix pickle_test (tests.test_re.ReTests) ... ERROR (run tests with
  nose) [Stephen L Arnold]
- Update changelog (and trigger ci rebuild) [Stephen L Arnold]
- Add missing tests to sdist package, update readme and ci worflows (#1)
  [Steve Arnold]

  readme: update badges, merge install sections, fix some rendering issues


v0.3.3 (2021-01-26)
-------------------

Changes
~~~~~~~
- Add .gitchangelog.rc and generated CHANGELOG.rst (keep HISTORY)
  [Stephen L Arnold]
- Ci: update wheel builds for Linux, Macos, and Windows. [Stephen L
  Arnold]

Fixes
~~~~~
- Ci: make sure wheel path is correct for uploading. [Stephen L Arnold]

Other
~~~~~
- Bump version. [Andreas van Cranenburgh]
- Update README.rst. fixes #21. [Andreas van Cranenburgh]
- Merge pull request #20 from freepn/new-bld. [Andreas van Cranenburgh]

  New cmake and pybind11 build setup


v0.3.2 (2020-12-16)
-------------------
- Bump version. [Andreas van Cranenburgh]
- Merge pull request #18 from freepn/github-ci. [Andreas van
  Cranenburgh]

  workaroud for manylinux dependency install error plus release automation


v0.3.1 (2020-10-27)
-------------------
- Bump version. [Andreas van Cranenburgh]
- Change package name for pypi. [Andreas van Cranenburgh]


v0.3 (2020-10-27)
-----------------
- Bump version. [Andreas van Cranenburgh]
- Merge pull request #14 from yoav-orca/master. [Andreas van
  Cranenburgh]

  Support building wheels automatically using github actions
- Creating github actions for building wheels. [Yoav Alon]
- Created pyproject.toml. [Yoav Alon]

  Poetry and other modern build system need to know which build-tools to
  install prior to calling setup.py. added a pyproject.toml to specify
  cython as a dependency.
- Add contains() method. [Andreas van Cranenburgh]

  - contains() works like match() but returns a bool to avoid creating a
    Match object. see #12
  - add wrapper for re.Pattern so that contains() and count() methods are
    also available when falling back to re.
- Disable dubious tests. [Andreas van Cranenburgh]

  - All tests pass.
  - Don't test for exotic/deprecated stuff such as non-initial flags in
    patterns and octal escapes without leading 0 or triple digits.
  - Known corner cases no longer reported as failed tests.
  - support \b inside character class to mean backspace
  - use re.error instead of defining subclass RegexError; ensures that
    exceptions can be caught both in re2 and in a potential fallback to re.
- Disable failing test for known corner case. [Andreas van Cranenburgh]
- Remove tests with re.LOCALE flag since it is not allowed with str in
  Python 3.6+ [Andreas van Cranenburgh]
- Decode named groups even with bytes patterns; fixes #6. [Andreas van
  Cranenburgh]
- Make -std=c++11 the default; fixes #4. [Andreas van Cranenburgh]
- Merge pull request #5 from mayk93/master. [Andreas van Cranenburgh]

  Adding c++ 11 compile flag on Ubuntu
- Adding c++ 11 compile flag on Ubuntu. [Michael]
- Merge pull request #3 from podhmo/macports. [Andreas van Cranenburgh]

  macports support
- Macports support. [podhmo]
- Use STL map for unicodeindices. [Andreas van Cranenburgh]
- Only translate unicode indices when needed. [Andreas van Cranenburgh]
- Update README. [Andreas van Cranenburgh]
- Add -std=c++11 only for clang, because gcc on CentOS 6 does not
  support it. [Andreas van Cranenburgh]
- Disable non-matched group tests; irrelevant after dad49cd. [Andreas
  van Cranenburgh]
- Merge pull request #2 from messense/master. [Andreas van Cranenburgh]

  Fix groupdict decode bug
- Fix groupdict decode bug. [messense]
- Merge pull request #1 from pvaneynd/master. [Andreas van Cranenburgh]

  Ignore non-matched groups when replacing with sub
- Ignore non-matched groups when replacing with sub. [Peter Van Eynde]

  From 3.5 onwards sub() and subn() now replace unmatched groups with
  empty strings. See:

  https://docs.python.org/3/whatsnew/3.5.html#re

  This change removes the 'unmatched group' error which occurs when using
  re2.
- Fix setup.py unicode error. [Andreas van Cranenburgh]
- Add C++11 param; update URL. [Andreas van Cranenburgh]
- Fix bugs; ensure memory is released; simplify C++ interfacing;
  [Andreas van Cranenburgh]

  - Fix bug causing zero-length matches to be returned multiple times
  - Use Latin 1 encoding with RE2 when unicode not requested
  - Ensure memory is released:
    - put del calls in finally blocks
    - add missing del call for 'matches' array
  - Remove Cython hacks for C++ that are no longer needed;
    use const keyword that has been supported for some time.
    Fixes Cython 0.24 compilation issue.
  - Turn _re2.pxd into includes.pxi.
  - remove some tests that are specific to internal Python modules _sre and sre
- Fix Match repr. [Andreas van Cranenburgh]
- Add tests for bug with \\b. [Andreas van Cranenburgh]
- Document support syntax &c. [Andreas van Cranenburgh]

  - add reference of supported syntax to main docstring
  - add __all__ attribute defining public members
  - add re's purge() function
  - add tests for count method
  - switch order of prepare_pattern() and _compile()
  - rename prepare_pattern() to _prepare_pattern() to signal that it is
    semi-private
- Add count method. [Andreas van Cranenburgh]

  - add count method, equivalent to len(findall(...))
  - use arrays in utf8indices
  - tweak docstrings
- Move functions around. [Andreas van Cranenburgh]
- Improve substitutions, Python 3 compatibility. [Andreas van
  Cranenburgh]

  - when running under Python 3+, reject unicode patterns on
    bytes data, and vice versa, in according with general Python 3 behavior.
  - improve Match.expand() implementation.
  - The substitutions by RE2 behave differently from Python (character escapes,
    named groups, etc.), so use Match.expand() for anything but simple literal
    replacement strings.
  - make groupindex of pattern objects public.
  - add Pattern.fullmatch() method.
  - use #define PY2 from setup.py instead of #ifdef hack.
  - debug option for compilation.
  - use data() instead of c_str() on C++ strings, and always supply length,
    so that strings with null characters are supported.
  - bump minimum cython version due to use of bytearray typing
  - adapt tests to Python 3; add b and u string prefixes where needed, &c.
  - update README
- Add flags parameter to toplevel functions. [Andreas van Cranenburgh]
- Update performance table / missing features. [Andreas van Cranenburgh]
- Workaround for sub(...) with count > 1. [Andreas van Cranenburgh]
- Handle named groups in replacement string; &c. [Andreas van
  Cranenburgh]

  - handle named groups in replacement string
  - store index of named groups in Pattern object instead of Match object.
  - use bytearray for result in _subn_callback
- Pickle Patterns; non-char buffers; &c. [Andreas van Cranenburgh]

  - support pickling of Pattern objects
  - support buffers from objects that do not support char buffer (e.g.,
    integer arrays); does not make a lot of sense, but this is what re does.
  - enable benchmarks shown in readme by default; fix typo.
  - fix typo in test_re.py
- New buffer API; precompute groups/spans; &c. [Andreas van Cranenburgh]

  - use new buffer API
    NB: even though the old buffer interface is deprecated from Python 2.6,
    the new buffer interface is only supported on mmap starting from
    Python 3.
  - avoid creating Match objects in findall()
  - precompute groups and spans of Match objects, so that possibly encoded
    version of search string (bytestr / cstring) does not need to be kept.
  - in _make_spans(), keep state for converting utf8 to unicode indices;
    so that there is no quadratic behavior on repeated invocations for
    different Match objects.
  - release GIL in pattern_Replace / pattern_GlobalReplace
  - prepare_pattern: loop over pattern as char *
  - advertise Python 3 support in setup.py, remove python 2.5
- Properly translate pos, endpos indices with unicode, &c. [Andreas van
  Cranenburgh]

  - properly translate pos, endpos indices with unicode
  - keep original unicode string in Match objects
  - separate compile.pxi file
- Re-organize code. [Andreas van Cranenburgh]
- Minor changes. [Andreas van Cranenburgh]
- Python 2/3 compatibility, support buffer objects, &c. [Andreas van
  Cranenburgh]

  - Python 2/3 compatibility
  - support searching in buffer objects (e.g., mmap)
  - add module docstring
  - some refactoring
  - remove outdated Cython-generated file
  - modify setup.py to cythonize as needed.
- Implement finditer as generator. [Andreas van Cranenburgh]
- Merge pull request #31 from sunu/master. [Michael Axiak]

  Add Python 3 support.
- Add Python 3 support. [Tarashish Mishra]
- Version bump. [Michael Axiak]


release/0.2.22 (2015-05-15)
---------------------------
- Version bump. [Michael Axiak]
- Merge pull request #22 from socketpair/release_gil_on_compile.
  [Michael Axiak]

  Release GIL during regex compilation.
- Release GIL during regex compilation. [Коренберг Марк]

  (src/re2.cpp is not regenerated in this commit)


release/0.2.21 (2015-05-14)
---------------------------
- Release bump. [Michael Axiak]
- Merge pull request #18 from offlinehacker/master. [Michael Axiak]

  setup.py: Continue with default lib paths if not detected automatically
- Setup.py: Continue with default lib paths if not detected
  automatically. [Jaka Hudoklin]
- Fix issue #11. [Michael Axiak]
- Remove spurious print statement. [Michael Axiak]
- Added version check in setup.py to prevent people from shooting
  themselves in the foot trying to compile with an old cython version.
  [Michael Axiak]


release/0.2.20 (2011-11-15)
---------------------------
- Version bump to 0.2.20. [Michael Axiak]
- Version bump to 0.2.18 and use MANIFEST.in since python broke how
  sdist works in 2.7.1 (but fixes it in 2.7.3...) [Michael Axiak]


release/0.2.16 (2011-11-08)
---------------------------

Fixes
~~~~~
- Unmatched group span (-1,-1) caused exception in _convert_pos. [Israel
  Tsadok]
- Last item in qualified split included the item before last. [Israel
  Tsadok]
- Exception in callback would cause a memory leak. [Israel Tsadok]
- Group spans need to be translated to their relative decoded positions.
  [Israel Tsadok]
- This is not what verbose means in this context. [Israel Tsadok]
- Findall used group(0) instead of group(1) when there was a group.
  [Israel Tsadok]
- Dangling reference when _subn_callback breaks on limit. [Israel
  Tsadok]
- Infinite loop in pathological case of findall(".*", "foo") [Israel
  Tsadok]

Other
~~~~~
- Version bump to 0.2.16. [Michael Axiak]
- Merged itsadok's changes to fix treatment of \D and \W. Added tests to
  reflection issue #4. [Michael Axiak]
- Fixed issue #5, support \W, \S and \D. [Israel Tsadok]
- Fixed issue #3, changed code to work with new re2 api. [Michael Axiak]
- Merge branch 'itsadok-master' [Michael Axiak]
- Merge branch 'master' of https://github.com/itsadok/pyre2 into
  itsadok-master. [Michael Axiak]
- Failing tests for pos and endpos. [Israel Tsadok]
- Set default notification to FALLBACK_QUIETLY, as per the
  documentation. [Israel Tsadok]
- Get rid of deprecation warning. [Israel Tsadok]
- Fix hang on findall('', 'x') [Israel Tsadok]
- Allow weak reference to Pattern object. [Israel Tsadok]
- Allow named groups in span(), convert all unicode positions in one
  scan. [Israel Tsadok]
- Added failing test for named groups. [Israel Tsadok]
- Fix lastgroup and lastindex. [Israel Tsadok]
- Verify that flags do not get silently ignored with compiled patterns.
  [Israel Tsadok]
- Had to cheat on a test, since we can't support arbitrary bytes.
  [Israel Tsadok]
- Fix lastindex. [Israel Tsadok]
- Pass some more tests - added pos, endpos, regs, re attributes to Match
  object. [Israel Tsadok]
- Added max_mem parameter, bumped version to 0.2.13. [Michael Axiak]
- Remove spurious get_authors() call. [Michael Axiak]
- Added Alex to the authors file. [Michael Axiak]
- Version bumped to 0.2.11. [Michael Axiak]
- Added difference in version to changelist, added AUTHORS parsing to
  setup.py. [Michael Axiak]
- Added check for array, added synonym 'error' for RegexError to help
  pass more python tests. [Michael Axiak]
- Made make test run a little nicer. [Michael Axiak]
- Added note about copyright assignment to authors. [Michael Axiak]
- Fix test_re_match. [Israel Tsadok]
- Fix test_bug_1140. [Israel Tsadok]
- Update readme. [Israel Tsadok]
- Preprocess pattern to match re2 quirks. Fixes several bugs. [Israel
  Tsadok]
- Re2 doesn't like when you escape non-ascii chars. [Israel Tsadok]
- Merge remote branch 'moreati/master' [Israel Tsadok]
- Merge from axiak/HEAD. [Alex Willmer]
- Merge from axiak/master. [Alex Willmer]
- Pass ErrorBadEscape patterns to re.compile(). Have re.compile() accept
  SRE objects. [Alex Willmer]
- Ignore .swp files. [Alex Willmer]
- Remove superfluous differences to axiak/master. [Alex Willmer]
- Merge remote branch 'upstream/master' [Alex Willmer]
- Merge changes from axiak master. [Alex Willmer]
- Fix previous additions to setup.py. [Alex Willmer]
- Add url to setup.py. [Alex Willmer]
- Remove #! line from re.py module, since it isn't a script. [Alex
  Willmer]
- Add classifers and long description to setup.py. [Alex Willmer]
- Add MANIFEST.in. [Alex Willmer]
- Merge branch 'master' of git://github.com/facebook/pyre2. [Alex
  Willmer]

  Conflicts:
  	re2.py
- Ignore byte compiled python files. [Alex Willmer]
- Add copyright, license, and three convenience functions to re2.py.
  [Alex Willmer]
- Switch re2.h include to angle brackets. [Alex Willmer]
- Handle \n in replace template, since re2 doesn't. [Israel Tsadok]
- Import escape function as it from re. [Israel Tsadok]
- The unicode char classes never worked. TIL testing is important.
  [Israel Tsadok]
- Make unicode stickyness rules like in re module. [Israel Tsadok]
- Return an iterator from finditer. [Israel Tsadok]
- Have re.compile() accept SRE objects. (copied from moreati's fork)
  [Israel Tsadok]
- Fix var name mixup. [Israel Tsadok]
- Added self to authors. [Israel Tsadok]
- Fix memory leak. [Israel Tsadok]
- Added re unit test from python2.6. [Israel Tsadok]
- Make match group allocation more RAII style. [Israel Tsadok]
- Use None for unused groups in split. [Israel Tsadok]
- Change split to match sre.c implementation, and handle empty matches.
  [Israel Tsadok]
- Match delete[] to new[] calls. [Israel Tsadok]
- Added group property to match re API. [Israel Tsadok]
- Use appropriate char classes in case of re.UNICODE. [Israel Tsadok]
- Fall back on re in case of back references. [Israel Tsadok]
- Use unmangled pattern in case of fallback to re. [Israel Tsadok]
- Simplistic cache, copied from re.py. [Israel Tsadok]
- Fix some memory leaks. [Israel Tsadok]
- Allow multiple arguments to group() [Israel Tsadok]
- Allow multiple arguments to group() [Israel Tsadok]
- Fixed path issues. [Michael Axiak]
- Added flags to pattern object, bumped version number. [Michael Axiak]
- Change import path to fix include dirs. [Michael Axiak]
- Updated manifest and changelog. [Michael Axiak]
- Added .expand() to group objects. [Michael Axiak]
- Removed the excessive thanks. [Michael Axiak]
- Added regex module to performance tests. [Michael Axiak]
- Pattern objects should be able to return the input pattern. [Alec
  Berryman]

  I'm just storing the original object passed in (found it could be str or
  unicode - thanks, unicode tests!).  It could be calculated if important
  to save space.
- Further findall fix: one-match finds. [Alec Berryman]

  I read the spec more carefully this time.
- Added changelist file for future releases. [Michael Axiak]
- Added alec to AUTHORS. Bumped potential version number. Fixed findall
  support to work without closures. [Michael Axiak]
- Make pyre2 64-bit safe. [Alec Berryman]

  Now compiles on a 64-bit system; previously, complained that you might
  have a string size that couldn't fit into an int.  Py_ssize_t is
  required instead of plain size_t because Python's is signed.
- Fix findall behavior to match re. [Alec Berryman]

  findall is to return a list of strings or tuples of strings, while
  finditer is to return an iterator of match objects; previously both were
  returning lists of match objects.  findall was fixed, but finditer is
  still returning a list.

  New tests.
- Makefile: test target. [Alec Berryman]
- Note Cython 0.13 dependency. [Alec Berryman]
- Moved to my own license. I can do that since I started the code from
  scratch. [Michael Axiak]
- Fix formatting of table. [Michael Axiak]
- Added number of trials, fixed some wording. [Michael Axiak]
- Added missing files to MANIFEST. [Michael Axiak]
- Added performance testing, bumped version number. [Michael Axiak]
- Added readme data. [Michael Axiak]
- Updated installation language. [Michael Axiak]
- Incremented version number. [Michael Axiak]
- Fixed split regression with missing unicode translation. [Michael
  Axiak]
- Maybe utf8 works? [Michael Axiak]
- Got unicode to past broken test. [Michael Axiak]
- Added debug message for issue with decoding. [Michael Axiak]
- Added more utf8 stuff. [Michael Axiak]
- Delay group construction for faster match testing. [Michael Axiak]
- Got utf8 support to work. [Michael Axiak]
- Starting to add unicode support... BROKEN. [Michael Axiak]
- Added fallback and notification. [Michael Axiak]
- Added runtime library path to fix /usr/local/ bug for installation of
  re2 library. [Michael Axiak]
- Fixed setup and updated readme. [Michael Axiak]
- Added more setup.py antics. [Michael Axiak]
- Added ancillary stuff. [Michael Axiak]
- Added sub, subn, findall, finditer, split. Bam. [Michael Axiak]
- Added finditer along with tests. [Michael Axiak]
- Fix rst. [Michael Axiak]
- Added contact link to readme. [Michael Axiak]
- Fixed formatting for readme. [Michael Axiak]
- Added lastindex, lastgroup, and updated README file. [Michael Axiak]
- Added some simple tests. Got match() to work, named groups to work.
  spanning to work. pretty much at the same level as pyre2 proper.
  [Michael Axiak]
- Added more things to gitignore, another compile. [Michael Axiak]
- Move code to src directory for better sanity. [Michael Axiak]
- Updated re2 module to use Cython instead, got matching working almost
  completely with minimal flag support. [Michael Axiak]
- Suppress logging of failed pattern compilation. [David Reiss]

  This isn't necessary in Python since errors are reported by exceptions.
  Use a slightly more verbose form to allow easier setting of more options
  later.
- Don't define tp_new for regexps and matches. [David Reiss]

  It turns out that these are not required to use PyObject_New.  They are
  only required to allow Python code to call the type to create a new
  instance, which I don't want to allow.  Remove them.
- Fix a segfault by initializing attr_dict to NULL. [David Reiss]

  I thought PyObject_New would call my tp_new, which is set to
  PyType_GenericNew, which NULLs out all user-defined fields (actually
  memset, but the docs say NULL).  However, this appears to not be the
  case.  Explicitly NULL out attr_dict in create_regexp to avoid segfaults
  when compiling a bad pattern.  Do it for create_match too for future
  safety, even though it is not required with the current code.
- Add struct tags for easier debugging with gdb. [David Reiss]

  See http://sourceware.org/ml/archer/2009-q1/msg00085.html for a little
  more information.
- Add some convenience functions to re2.py. [Alex Willmer]
- Add a copyright and license comment to re2.py. [David Reiss]

  This is to prepare for adding some not-totally-trivial code to it.
- Use PEP-8-compliant 4-space indent in re2.py. [David Reiss]
- Use angle-brackets for the re2.h include. [Alex Willmer]
- Add build information to the README. [David Reiss]
- Add contact info to README. [David Reiss]
- Initial commit of pyre2. [David Reiss]


