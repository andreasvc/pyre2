# cython: infer_types(False)
"""Regular expressions using Google's RE2 engine.

Compared to Python's ``re``, the RE2 engine converts regular expressions to
deterministic finite automata, which guarantees linear-time behavior.

Intended as a drop-in replacement for ``re``. Unicode is supported by encoding
to UTF-8, and bytes strings are treated as UTF-8. For best performance, work
with UTF-8 encoded bytes strings.

Regular expressions that are not compatible with RE2 are processed with
fallback to ``re``. Examples of features not supported by RE2:

    - lookahead assertions ``(?!...)``
    - backreferences (``\\n`` in search pattern)
    - \W and \S not supported inside character classes

On the other hand, unicode character classes are supported.
Syntax reference: https://github.com/google/re2/wiki/Syntax
"""

# Import re flags to be compatible.
import sys
import re

I = re.I
M = re.M
S = re.S
U = re.U
X = re.X
L = re.L
IGNORECASE = re.IGNORECASE
MULTILINE = re.MULTILINE
DOTALL = re.DOTALL
UNICODE = re.UNICODE
VERBOSE = re.VERBOSE
LOCALE = re.LOCALE

cdef int _I = re.I
cdef int _M = re.M
cdef int _S = re.S
cdef int _U = re.U
cdef int _X = re.X
cdef int _L = re.L

FALLBACK_QUIETLY = 0
FALLBACK_WARNING = 1
FALLBACK_EXCEPTION = 2

VERSION = (0, 2, 23)
VERSION_HEX = 0x000217
cdef int current_notification = FALLBACK_QUIETLY

# Type of compiled re object from Python stdlib
SREPattern = type(re.compile(''))


class RegexError(re.error):
    """ome error has occured in compilation of the regex."""
    pass

error = RegexError


class BackreferencesException(Exception):
    """Search pattern contains backreferences."""
    pass


class CharClassProblemException(Exception):
    """Search pattern contains unsupported character class."""
    pass


def set_fallback_notification(level):
    """Set the fallback notification to a level; one of:
        FALLBACK_QUIETLY
        FALLBACK_WARNING
        FALLBACK_EXCEPTION
    """
    global current_notification
    level = int(level)
    if level < 0 or level > 2:
        raise ValueError("This function expects a valid notification level.")
    current_notification = level




cimport _re2
cimport cpython.unicode
from cython.operator cimport preincrement as inc, dereference as deref
import warnings


cdef bytes cpp_to_bytes(_re2.cpp_string input):
    """Convert from a std::string object to a python string."""
    # By taking the slice we go to the right size,
    # despite spurious or missing null characters.
    return input.c_str()[:input.length()]


cdef inline unicode cpp_to_unicode(_re2.cpp_string input):
    """Convert a std::string object to a unicode string."""
    return cpython.unicode.PyUnicode_DecodeUTF8(
            input.c_str(), input.length(), 'strict')


cdef inline unicode char_to_unicode(_re2.const_char_ptr input, int length):
    """Convert a C string to a unicode string."""
    return cpython.unicode.PyUnicode_DecodeUTF8(input, length, 'strict')


cdef inline unicode_to_bytes(object pystring, int * encoded):
    """Convert a unicode string to a utf8 bytes object, if necessary.
 
    If pystring is a bytes string or a buffer, return unchanged."""
    if cpython.unicode.PyUnicode_Check(pystring):
        pystring = cpython.unicode.PyUnicode_EncodeUTF8(
                cpython.unicode.PyUnicode_AS_UNICODE(pystring),
                cpython.unicode.PyUnicode_GET_SIZE(pystring),
                "strict")
        encoded[0] = 1
    else:
        encoded[0] = 0
    return pystring


cdef inline int pystring_to_cstring(
        object pystring, char ** cstring, Py_ssize_t * length):
    """Get a C string from a bytes/buffer object."""
    # Place the char * in cstring, and the length in length.
    # First it will try treating it as a str object, but failing that
    # it will move to utf-8. If utf8 does not work, then it has to be
    # a non-supported encoding.
    return _re2.PyObject_AsCharBuffer(
            pystring, <_re2.const_char_ptr*> cstring, length)
    # FIXME: use Python 3 buffer interface when available


cdef extern from *:
    cdef void emit_ifndef_py_unicode_wide "#if !defined(Py_UNICODE_WIDE) //" ()
    cdef void emit_endif "#endif //" ()


cdef class Match:
    cdef readonly Pattern re
    cdef readonly object string
    cdef readonly int pos
    cdef readonly int endpos

    cdef _re2.StringPiece * matches
    cdef _re2.const_stringintmap * named_groups
    cdef bint encoded
    cdef int nmatches
    cdef int _lastindex
    cdef tuple _groups
    cdef tuple _spans
    cdef dict _named_groups
    cdef dict _named_indexes

    def __init__(self, Pattern pattern_object, int num_groups):
        self._lastindex = -1
        self._groups = None
        self.pos = 0
        self.endpos = -1
        self.matches = _re2.new_StringPiece_array(num_groups + 1)
        self.nmatches = num_groups
        self.re = pattern_object

    def __dealloc__(self):
       _re2.delete_StringPiece_array(self.matches)

    def __repr__(self):
        return '<re2.Match object; span=%r, match=%r>' % (
                (self.pos, self.endpos), self.string)

    cdef init_groups(self):
        cdef list groups = []
        cdef int i

        if self._groups is not None:
            return

        cdef _re2.const_char_ptr last_end = NULL
        cdef _re2.const_char_ptr cur_end = NULL

        for i in range(self.nmatches):
            if self.matches[i].data() == NULL:
                groups.append(None)
            else:
                if i > 0:
                    cur_end = self.matches[i].data() + self.matches[i].length()

                    if last_end == NULL:
                        last_end = cur_end
                        self._lastindex = i
                    else:
                        # The rules for last group are a bit complicated:
                        # if two groups end at the same point, the earlier one
                        # is considered last, so we don't switch our selection
                        # unless the end point has moved.
                        if cur_end > last_end:
                            last_end = cur_end
                            self._lastindex = i
                groups.append(
                        self.matches[i].data()[:self.matches[i].length()])
        self._groups = tuple(groups)

    def groups(self, default=None):
        self.init_groups()
        if self.encoded:
            return tuple([
                g.decode('utf8') if g else default
                for g in self._groups[1:]])
        if default is not None:
            return tuple([g or default for g in self._groups[1:]])
        return self._groups[1:]

    def group(self, *args):
        if len(args) == 0:
            groupnum = 0
        elif len(args) == 1:
            groupnum = args[0]
        else:  # len(args) > 1:
            return tuple([self.group(i) for i in args])
        if self.encoded:
            return self._group(groupnum).decode('utf8')
        return self._group(groupnum)

    cdef bytes _group(self, object groupnum):
        cdef int idx
        self.init_groups()
        if isinstance(groupnum, int):
            idx = groupnum
            if idx > self.nmatches - 1:
                raise IndexError("no such group %d; available groups: %r"
                        % (idx, list(range(self.nmatches))))
            return self._groups[idx]
        groupdict = self._groupdict()
        if groupnum not in groupdict:
            raise IndexError("no such group %r; available groups: %r"
                    % (groupnum, list(groupdict.keys())))
        return groupdict[groupnum]

    cdef list _convert_positions(self, positions):
        cdef char * s
        cdef int cpos = 0
        cdef int upos = 0
        cdef Py_ssize_t size
        cdef int c
        if pystring_to_cstring(self.string, &s, &size) == -1:
            raise TypeError("expected string or buffer")

        new_positions = []
        i = 0
        num_positions = len(positions)
        if positions[i] == -1:
            new_positions.append(-1)
            inc(i)
            if i == num_positions:
                return new_positions
        if positions[i] == 0:
            new_positions.append(0)
            inc(i)
            if i == num_positions:
                return new_positions

        while cpos < size:
            c = <unsigned char>s[cpos]
            if c < 0x80:
                inc(cpos)
                inc(upos)
            elif c < 0xe0:
                cpos += 2
                inc(upos)
            elif c < 0xf0:
                cpos += 3
                inc(upos)
            else:
                cpos += 4
                inc(upos)
                # wide unicode chars get 2 unichars when python is compiled
                # with --enable-unicode=ucs2
                # TODO: verify this
                emit_ifndef_py_unicode_wide()
                inc(upos)
                emit_endif()

            if positions[i] == cpos:
                new_positions.append(upos)
                inc(i)
                if i == num_positions:
                    return new_positions

    def _convert_spans(self, spans):
        positions = [x for x, _ in spans] + [y for _, y in spans]
        positions = sorted(set(positions))
        posdict = dict(zip(positions, self._convert_positions(positions)))

        return [(posdict[x], posdict[y]) for x, y in spans]


    cdef _make_spans(self):
        if self._spans is not None:
            return

        cdef int start, end
        cdef char * s
        cdef Py_ssize_t size
        cdef _re2.StringPiece * piece
        if pystring_to_cstring(self.string, &s, &size) == -1:
            raise TypeError("expected string or buffer")

        spans = []
        for i in range(self.nmatches):
            if self.matches[i].data() == NULL:
                spans.append((-1, -1))
            else:
                piece = &self.matches[i]
                if piece.data() == NULL:
                    return (-1, -1)
                start = piece.data() - s
                end = start + piece.length()
                spans.append((start, end))

        if self.encoded:
            spans = self._convert_spans(spans)

        self._spans = tuple(spans)

    def expand(self, object template):
        """Expand a template with groups."""
        # TODO - This can be optimized to work a bit faster in C.
        if isinstance(template, unicode):
            template = template.encode('utf8')
        items = template.split(b'\\')
        for i, item in enumerate(items[1:]):
            if item[0:1].isdigit():
                # Number group
                if item[0] == b'0':
                    items[i + 1] = b'\x00' + item[1:]  # ???
                else:
                    items[i + 1] = self._group(int(item[0:1])) + item[1:]
            elif item[:2] == b'g<' and b'>' in item:
                # This is a named group
                name, rest = item[2:].split(b'>', 1)
                items[i + 1] = self._group(name) + rest
            else:
                # This isn't a template at all
                items[i + 1] = b'\\' + item
        if self.encoded:
            return b''.join(items).decode('utf8')
        return b''.join(items)

    cdef dict _groupdict(self):
        cdef _re2.stringintmapiterator it
        cdef dict result = {}
        cdef dict indexes = {}

        self.init_groups()

        if self._named_groups:
            return self._named_groups

        self._named_groups = result
        it = self.named_groups.begin()
        while it != self.named_groups.end():
            indexes[cpp_to_bytes(deref(it).first)] = deref(it).second
            result[cpp_to_bytes(deref(it).first)] = self._groups[
                    deref(it).second]
            inc(it)

        self._named_groups = result
        self._named_indexes = indexes
        return result

    def groupdict(self):
        result = self._groupdict()
        if self.encoded:
            return {a.decode('utf8') if isinstance(a, bytes) else a:
                    b.decode('utf8') for a, b in result.items()}
        return result

    def end(self, group=0):
        return self.span(group)[1]

    def start(self, group=0):
        return self.span(group)[0]

    def span(self, group=0):
        self._make_spans()
        if isinstance(group, int):
            if group > len(self._spans):
                raise IndexError("no such group %d; available groups: %r"
                        % (group, list(range(len(self._spans)))))
            return self._spans[group]
        else:
            self._groupdict()
            if self.encoded:
                group = group.encode('utf8')
            if group not in self._named_indexes:
                raise IndexError("no such group %r; available groups: %r"
                        % (group, list(self._named_indexes)))
            return self._spans[self._named_indexes[group]]

    property regs:
        def __get__(self):
            if self._spans is None:
                self._make_spans()
            return self._spans

    property lastindex:
        def __get__(self):
            self.init_groups()
            if self._lastindex < 1:
                return None
            else:
                return self._lastindex

    property lastgroup:
        def __get__(self):
            self.init_groups()
            cdef _re2.stringintmapiterator it

            if self._lastindex < 1:
                return None

            it = self.named_groups.begin()
            while it != self.named_groups.end():
                if deref(it).second == self._lastindex:
                    return cpp_to_bytes(deref(it).first)
                inc(it)

            return None


cdef class Pattern:
    cdef readonly int flags
    cdef readonly int groups
    cdef readonly object pattern

    cdef _re2.RE2 * re_pattern
    cdef bint encoded
    cdef object __weakref__

    def __dealloc__(self):
        del self.re_pattern

    def __repr__(self):
        return 're2.compile(%r, %r)' % (self.pattern, self.flags)

    cdef _search(self, string, int pos, int endpos, _re2.re2_Anchor anchoring):
        """Scan through string looking for a match, and return a corresponding
        Match instance. Return None if no position in the string matches."""
        cdef Py_ssize_t size
        cdef int result
        cdef char * cstring
        cdef int encoded = 0
        cdef _re2.StringPiece * sp
        cdef Match m = Match(self, self.groups + 1)

        if hasattr(string, 'tostring'):
            string = string.tostring()

        string = unicode_to_bytes(string, &encoded)

        if pystring_to_cstring(string, &cstring, &size) == -1:
            raise TypeError("expected string or buffer")

        if endpos >= 0 and endpos <= pos:
            return None

        if endpos >= 0 and endpos < size:
            size = endpos

        if pos > size:
            return None

        sp = new _re2.StringPiece(cstring, size)
        with nogil:
            result = self.re_pattern.Match(
                    sp[0],
                    <int>pos,
                    <int>size,
                    anchoring,
                    m.matches,
                    self.groups + 1)

        del sp
        if result == 0:
            return None
        m.encoded = <bint>(encoded)
        m.named_groups = _re2.addressof(self.re_pattern.NamedCapturingGroups())
        m.nmatches = self.groups + 1
        m.string = string
        m.pos = pos
        if endpos == -1:
            m.endpos = len(string)
        else:
            m.endpos = endpos
        return m

    def search(self, object string, int pos=0, int endpos=-1):
        """Scan through string looking for a match, and return a corresponding
        Match instance. Return None if no position in the string matches."""
        return self._search(string, pos, endpos, _re2.UNANCHORED)

    def match(self, object string, int pos=0, int endpos=-1):
        """Matches zero or more characters at the beginning of the string."""
        return self._search(string, pos, endpos, _re2.ANCHOR_START)

    def _print_pattern(self):
        cdef _re2.cpp_string * s
        s = <_re2.cpp_string *>_re2.addressofs(self.re_pattern.pattern())
        print(cpp_to_bytes(s[0]).decode('utf8'))

    def finditer(self, object string, int pos=0, int endpos=-1):
        """Yield all non-overlapping matches of pattern in string as Match
        objects."""
        cdef Py_ssize_t size
        cdef int result
        cdef char * cstring
        cdef _re2.StringPiece * sp
        cdef Match m
        cdef int encoded = 0

        string = unicode_to_bytes(string, &encoded)
        if pystring_to_cstring(string, &cstring, &size) == -1:
            raise TypeError("expected string or buffer")
        encoded = <bint>encoded

        if endpos != -1 and endpos < size:
            size = endpos

        sp = new _re2.StringPiece(cstring, size)

        while True:
            m = Match(self, self.groups + 1)
            with nogil:
                result = self.re_pattern.Match(
                        sp[0],
                        <int>pos,
                        <int>size,
                        _re2.UNANCHORED,
                        m.matches,
                        self.groups + 1)
            if result == 0:
                break
            m.encoded = encoded
            m.named_groups = _re2.addressof(
                    self.re_pattern.NamedCapturingGroups())
            m.nmatches = self.groups + 1
            m.string = string
            m.pos = pos
            if endpos == -1:
                m.endpos = len(string)
            else:
                m.endpos = endpos
            yield m
            if pos == size:
                break
            # offset the pos to move to the next point
            if m.matches[0].length() == 0:
                pos += 1
            else:
                pos = m.matches[0].data() - cstring + m.matches[0].length()
        del sp

    def findall(self, object string, int pos=0, int endpos=-1):
        """Return all non-overlapping matches of pattern in string as a list
        of strings."""
        cdef Py_ssize_t size
        cdef int result
        cdef char * cstring
        cdef _re2.StringPiece * sp
        cdef Match m
        cdef list resultlist = []
        cdef int encoded = 0

        string = unicode_to_bytes(string, &encoded)
        if pystring_to_cstring(string, &cstring, &size) == -1:
            raise TypeError("expected string or buffer")
        encoded = <bint>encoded

        if endpos != -1 and endpos < size:
            size = endpos

        sp = new _re2.StringPiece(cstring, size)

        while True:
            # FIXME: can probably avoid creating Match objects
            m = Match(self, self.groups + 1)
            with nogil:
                result = self.re_pattern.Match(
                        sp[0],
                        <int>pos,
                        <int>size,
                        _re2.UNANCHORED,
                        m.matches,
                        self.groups + 1)
            if result == 0:
                break
            m.encoded = encoded
            m.named_groups = _re2.addressof(
                    self.re_pattern.NamedCapturingGroups())
            m.nmatches = self.groups + 1
            m.string = string
            m.pos = pos
            if endpos == -1:
                m.endpos = len(string)
            else:
                m.endpos = endpos
            if self.groups > 1:
                resultlist.append(m.groups(""))
            else:
                resultlist.append(m.group(self.groups))
            if pos == size:
                break
            # offset the pos to move to the next point
            if m.matches[0].length() == 0:
                pos += 1
            else:
                pos = m.matches[0].data() - cstring + m.matches[0].length()
        del sp
        return resultlist

    def split(self, string, int maxsplit=0):
        """split(string[, maxsplit = 0]) --> list

        Split a string by the occurrences of the pattern."""
        cdef Py_ssize_t size
        cdef int result
        cdef int pos = 0
        cdef int lookahead = 0
        cdef int num_split = 0
        cdef char * cstring
        cdef _re2.StringPiece * sp
        cdef _re2.StringPiece * matches
        cdef list resultlist = []
        cdef int encoded = 0

        if maxsplit < 0:
            maxsplit = 0

        string = unicode_to_bytes(string, &encoded)
        if pystring_to_cstring(string, &cstring, &size) == -1:
            raise TypeError("expected string or buffer")

        matches = _re2.new_StringPiece_array(self.groups + 1)
        sp = new _re2.StringPiece(cstring, size)

        while True:
            with nogil:
                result = self.re_pattern.Match(
                        sp[0],
                        <int>(pos + lookahead),
                        <int>size,
                        _re2.UNANCHORED,
                        matches,
                        self.groups + 1)
            if result == 0:
                break

            match_start = matches[0].data() - cstring
            match_end = match_start + matches[0].length()

            # If an empty match, just look ahead until you find something
            if match_start == match_end:
                if pos + lookahead == size:
                    break
                lookahead += 1
                continue

            if encoded:
                resultlist.append(
                        char_to_unicode(&sp.data()[pos], match_start - pos))
            else:
                resultlist.append(sp.data()[pos:match_start])
            if self.groups > 0:
                for group in range(self.groups):
                    if matches[group + 1].data() == NULL:
                        resultlist.append(None)
                    else:
                        if encoded:
                            resultlist.append(char_to_unicode(
                                    matches[group + 1].data(),
                                    matches[group + 1].length()))
                        else:
                            resultlist.append(matches[group + 1].data()[:
                                        matches[group + 1].length()])

            # offset the pos to move to the next point
            pos = match_end
            lookahead = 0

            num_split += 1
            if maxsplit and num_split >= maxsplit:
                break

        if encoded:
            resultlist.append(
                    char_to_unicode(&sp.data()[pos], sp.length() - pos))
        else:
            resultlist.append(sp.data()[pos:])
        _re2.delete_StringPiece_array(matches)
        del sp
        return resultlist

    def sub(self, repl, string, int count=0):
        """sub(repl, string[, count = 0]) --> newstring

        Return the string obtained by replacing the leftmost non-overlapping
        occurrences of pattern in string by the replacement repl."""
        return self.subn(repl, string, count)[0]

    def subn(self, repl, string, int count=0):
        """subn(repl, string[, count = 0]) --> (newstring, number of subs)

        Return the tuple (new_string, number_of_subs_made) found by replacing
        the leftmost non-overlapping occurrences of pattern with the
        replacement repl."""
        cdef Py_ssize_t size
        cdef char * cstring
        cdef _re2.cpp_string * fixed_repl
        cdef _re2.StringPiece * sp
        cdef _re2.cpp_string * input_str
        cdef total_replacements = 0
        cdef int string_encoded = 0
        cdef int repl_encoded = 0

        if callable(repl):
            # This is a callback, so let's use the custom function
            return self._subn_callback(repl, string, count)

        string = unicode_to_bytes(string, &string_encoded)
        repl = unicode_to_bytes(repl, &repl_encoded)
        if pystring_to_cstring(repl, &cstring, &size) == -1:
            raise TypeError("expected string or buffer")

        fixed_repl = NULL
        cdef _re2.const_char_ptr s = cstring
        cdef _re2.const_char_ptr end = s + size
        cdef int c = 0
        while s < end:
            c = s[0]
            if (c == b'\\'):
                s += 1
                if s == end:
                    raise RegexError("Invalid rewrite pattern")
                c = s[0]
                if c == b'\\' or (c >= b'0' and c <= b'9'):
                    if fixed_repl != NULL:
                        fixed_repl.push_back(b'\\')
                        fixed_repl.push_back(c)
                else:
                    if fixed_repl == NULL:
                        fixed_repl = new _re2.cpp_string(
                                cstring, s - cstring - 1)
                    if c == b'n':
                        fixed_repl.push_back(b'\n')
                    else:
                        fixed_repl.push_back(b'\\')
                        fixed_repl.push_back(b'\\')
                        fixed_repl.push_back(c)
            else:
                if fixed_repl != NULL:
                    fixed_repl.push_back(c)

            s += 1
        if fixed_repl != NULL:
            sp = new _re2.StringPiece(fixed_repl.c_str())
        else:
            sp = new _re2.StringPiece(cstring, size)

        input_str = new _re2.cpp_string(string)
        if not count:
            total_replacements = _re2.pattern_GlobalReplace(
                    input_str, self.re_pattern[0], sp[0])
        elif count == 1:
            total_replacements = _re2.pattern_Replace(
                    input_str, self.re_pattern[0], sp[0])
        else:
            del fixed_repl
            del input_str
            del sp
            raise NotImplementedError(
                    "So far pyre2 does not support custom replacement counts")

        if string_encoded or (repl_encoded and total_replacements > 0):
            result = cpp_to_unicode(input_str[0])
        else:
            result = cpp_to_bytes(input_str[0])
        del fixed_repl
        del input_str
        del sp
        return (result, total_replacements)

    def _subn_callback(self, callback, string, int count=0):
        # This function is probably the hardest to implement correctly.
        # This is my first attempt, but if anybody has a better solution,
        # please help out.
        cdef Py_ssize_t size
        cdef int result
        cdef int endpos
        cdef int pos = 0
        cdef int encoded = 0
        cdef int num_repl = 0
        cdef char * cstring
        cdef _re2.StringPiece * sp
        cdef Match m
        cdef list resultlist = []

        if count < 0:
            count = 0

        string = unicode_to_bytes(string, &encoded)
        if pystring_to_cstring(string, &cstring, &size) == -1:
            raise TypeError("expected string or buffer")
        encoded = <bint>encoded

        sp = new _re2.StringPiece(cstring, size)

        try:
            while True:
                m = Match(self, self.groups + 1)
                with nogil:
                    result = self.re_pattern.Match(
                            sp[0],
                            <int>pos,
                            <int>size,
                            _re2.UNANCHORED,
                            m.matches,
                            self.groups + 1)
                if result == 0:
                    break

                endpos = m.matches[0].data() - cstring
                if encoded:
                    resultlist.append(
                            char_to_unicode(&sp.data()[pos], endpos - pos))
                else:
                    resultlist.append(sp.data()[pos:endpos])
                pos = endpos + m.matches[0].length()

                m.encoded = encoded
                m.named_groups = _re2.addressof(
                        self.re_pattern.NamedCapturingGroups())
                m.nmatches = self.groups + 1
                m.string = string
                resultlist.append(callback(m) or '')

                num_repl += 1
                if count and num_repl >= count:
                    break

            if encoded:
                resultlist.append(
                        char_to_unicode(&sp.data()[pos], sp.length() - pos))
                return (u''.join(resultlist), num_repl)
            else:
                resultlist.append(sp.data()[pos:])
                return (b''.join(resultlist), num_repl)
        finally:
            del sp

_cache = {}
_cache_repl = {}

_MAXCACHE = 100

def compile(pattern, int flags=0, int max_mem=8388608):
    cachekey = (type(pattern), pattern, flags)
    if cachekey in _cache:
        return _cache[cachekey]
    p = _compile(pattern, flags, max_mem)

    if len(_cache) >= _MAXCACHE:
        _cache.popitem()
    _cache[cachekey] = p
    return p


WHITESPACE = b' \t\n\r\v\f'


cdef class Tokenizer:
    cdef bytes string
    cdef bytes next
    cdef int length
    cdef int index

    def __init__(self, bytes string):
        self.string = string
        self.length = len(string)
        self.index = 0
        self._next()

    cdef _next(self):
        cdef bytes ch
        if self.index >= self.length:
            self.next = None
            return
        ch = self.string[self.index:self.index + 1]
        if ch[0:1] == b'\\':
            if self.index + 2 > self.length:
                raise RegexError("bogus escape (end of line)")
            ch = self.string[self.index:self.index + 2]
            self.index += 1
        self.index += 1
        # FIXME: return indices instead of creating new bytes objects
        self.next = ch

    cdef bytes get(self):
        cdef bytes this = self.next
        self._next()
        return this


def prepare_pattern(object pattern, int flags):
    cdef bytearray result = bytearray()
    cdef bytes this
    cdef Tokenizer source = Tokenizer(pattern)

    if flags & (_S | _M):
        result.extend(b'(?')
        if flags & _S:
            result.append(b's')
        if flags & _M:
            result.append(b'm')
        result.append(b')')

    while True:
        this = source.get()
        if this is None:
            break
        if flags & _X:
            if this in WHITESPACE:
                continue
            if this == b"#":
                while True:
                    this = source.get()
                    if this in (None, b'\n'):
                        break
                continue

        if this[0:1] != b'[' and this[0:1] != b'\\':
            result.extend(this)
            continue

        elif this == b'[':
            result.extend(this)
            while True:
                this = source.get()
                if this is None:
                    raise RegexError("unexpected end of regular expression")
                elif this == b']':
                    result.extend(this)
                    break
                elif this[0:1] == b'\\':
                    if flags & _U:
                        if this[1:2] == b'd':
                            result.extend(br'\p{Nd}')
                        elif this[1:2] == b'w':
                            result.extend(br'_\p{L}\p{Nd}')
                        elif this[1:2] == b's':
                            result.extend(br'\s\p{Z}')
                        elif this[1:2] == b'D':
                            result.extend(br'\P{Nd}')
                        elif this[1:2] == b'W':
                            # Since \w and \s are made out of several character
                            # groups, I don't see a way to convert their
                            # complements into a group without rewriting the
                            # whole expression, which seems too complicated.
                            raise CharClassProblemException(repr(this))
                        elif this[1:2] == b'S':
                            raise CharClassProblemException(repr(this))
                        else:
                            result.extend(this)
                    else:
                        result.extend(this)
                else:
                    result.extend(this)
        elif this[0:1] == b'\\':
            if b'8' <= this[1:2] <= b'9':
                raise BackreferencesException('%r %r' % (this, pattern))
            elif b'1' <= this[1:2] <= b'7':
                if source.next and source.next in b'1234567':
                    this += source.get()
                    if source.next and source.next in b'1234567':
                        # all clear, this is an octal escape
                        result.extend(this)
                    else:
                        raise BackreferencesException('%r %r' % (this, pattern))
                else:
                    raise BackreferencesException('%r %r' % (this, pattern))
            elif flags & _U:
                if this[1:2] == b'd':
                    result.extend(br'\p{Nd}')
                elif this[1:2] == b'w':
                    result.extend(br'[_\p{L}\p{Nd}]')
                elif this[1:2] == b's':
                    result.extend(br'[\s\p{Z}]')
                elif this[1:2] == b'D':
                    result.extend(br'[^\p{Nd}]')
                elif this[1:2] == b'W':
                    result.extend(br'[^_\p{L}\p{Nd}]')
                elif this[1:2] == b'S':
                    result.extend(br'[^\s\p{Z}]')
                else:
                    result.extend(this)
            else:
                result.extend(this)

    return <bytes>result


def _compile(object pattern, int flags=0, int max_mem=8388608):
    """Compile a regular expression pattern, returning a pattern object."""
    cdef char * string
    cdef Py_ssize_t length
    cdef _re2.StringPiece * s
    cdef _re2.Options opts
    cdef int error_code
    cdef int encoded = 0

    if isinstance(pattern, (Pattern, SREPattern)):
        if flags:
            raise ValueError(
                    'Cannot process flags argument with a compiled pattern')
        return pattern

    cdef object original_pattern = pattern
    pattern = unicode_to_bytes(pattern, &encoded)
    try:
        pattern = prepare_pattern(pattern, flags)
    except BackreferencesException:
        error_msg = "Backreferences not supported"
        if current_notification == <int>FALLBACK_EXCEPTION:
            # Raise an exception regardless of the type of error.
            raise RegexError(error_msg)
        elif current_notification == <int>FALLBACK_WARNING:
            warnings.warn("WARNING: Using re module. Reason: %s" % error_msg)
        return re.compile(original_pattern, flags)
    except CharClassProblemException:
        error_msg = "\W and \S not supported inside character classes"
        if current_notification == <int>FALLBACK_EXCEPTION:
            # Raise an exception regardless of the type of error.
            raise RegexError(error_msg)
        elif current_notification == <int>FALLBACK_WARNING:
            warnings.warn("WARNING: Using re module. Reason: %s" % error_msg)
        return re.compile(original_pattern, flags)

    # Set the options given the flags above.
    if flags & _I:
        opts.set_case_sensitive(0);

    opts.set_max_mem(max_mem)
    opts.set_log_errors(0)
    opts.set_encoding(_re2.EncodingUTF8)

    # We use this function to get the proper length of the string.
    if pystring_to_cstring(pattern, &string, &length) == -1:
        raise TypeError("first argument must be a string or compiled pattern")
    s = new _re2.StringPiece(string, length)

    cdef _re2.RE2 *re_pattern
    with nogil:
         re_pattern = new _re2.RE2(s[0], opts)

    if not re_pattern.ok():
        # Something went wrong with the compilation.
        del s
        error_msg = cpp_to_bytes(re_pattern.error())
        error_code = re_pattern.error_code()
        del re_pattern
        if current_notification == <int>FALLBACK_EXCEPTION:
            # Raise an exception regardless of the type of error.
            raise RegexError(error_msg)
        elif error_code not in (_re2.ErrorBadPerlOp, _re2.ErrorRepeatSize,
                                _re2.ErrorBadEscape):
            # Raise an error because these will not be fixed by using the
            # ``re`` module.
            raise RegexError(error_msg)
        elif current_notification == <int>FALLBACK_WARNING:
            warnings.warn("WARNING: Using re module. Reason: %s" % error_msg)
        return re.compile(original_pattern, flags)

    cdef Pattern pypattern = Pattern()
    pypattern.pattern = original_pattern
    pypattern.re_pattern = re_pattern
    pypattern.groups = re_pattern.NumberOfCapturingGroups()
    pypattern.encoded = <bint>encoded
    pypattern.flags = flags
    del s
    return pypattern


def search(pattern, string, int flags=0):
    """Scan through string looking for a match to the pattern, returning
    a match object or none if no match was found."""
    return compile(pattern, flags).search(string)


def match(pattern, string, int flags=0):
    """Try to apply the pattern at the start of the string, returning
    a match object, or None if no match was found."""
    return compile(pattern, flags).match(string)


def finditer(pattern, string, int flags=0):
    """Return an list of all non-overlapping matches in the
    string.  For each match, the iterator returns a match object.

    Empty matches are included in the result."""
    return compile(pattern, flags).finditer(string)


def findall(pattern, string, int flags=0):
    """Return an list of all non-overlapping matches in the
    string.  For each match, the iterator returns a match object.

    Empty matches are included in the result."""
    return compile(pattern, flags).findall(string)


def split(pattern, string, int maxsplit=0):
    """Split the source string by the occurrences of the pattern,
    returning a list containing the resulting substrings."""
    return compile(pattern).split(string, maxsplit)


def sub(pattern, repl, string, int count=0):
    """Return the string obtained by replacing the leftmost
    non-overlapping occurrences of the pattern in string by the
    replacement repl.  repl can be either a string or a callable;
    if a string, backslash escapes in it are processed.  If it is
    a callable, it's passed the match object and must return
    a replacement string to be used."""
    return compile(pattern).sub(repl, string, count)


def subn(pattern, repl, string, int count=0):
    """Return a 2-tuple containing (new_string, number).
    new_string is the string obtained by replacing the leftmost
    non-overlapping occurrences of the pattern in the source
    string by the replacement repl.  number is the number of
    substitutions that were made. repl can be either a string or a
    callable; if a string, backslash escapes in it are processed.
    If it is a callable, it's passed the match object and must
    return a replacement string to be used."""
    return compile(pattern).subn(repl, string, count)


_alphanum = {}
for c in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890':
    _alphanum[c] = 1
del c


def escape(pattern):
    "Escape all non-alphanumeric characters in pattern."
    s = list(pattern)
    alphanum = _alphanum
    for i in range(len(pattern)):
        c = pattern[i]
        if ord(c) < 0x80 and c not in alphanum:
            if c == "\000":
                s[i] = "\\000"
            else:
                s[i] = "\\" + c
    return pattern[:0].join(s)

