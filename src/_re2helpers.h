#ifndef PYRE2_HELPERS_H
#define PYRE2_HELPERS_H

#include <algorithm>
#include <string>
#include <vector>

#include "re2/re2.h"

static inline re2::StringPiece * new_StringPiece_array(int n)
{
    re2::StringPiece * sp = new re2::StringPiece[n];
    return sp;
}

static inline int re2_replace_from_piece(
        re2::StringPiece input, const re2::RE2 *pattern,
        re2::StringPiece rewrite, int count, std::string *output)
{
    output->clear();
    output->reserve(input.size());
    if (count < 0) {
        output->append(input.data(), input.size());
        return 0;
    }

    const int match_count = re2::RE2::MaxSubmatch(rewrite) + 1;
    std::vector<re2::StringPiece> matches(match_count);
    int replacements = 0;
    int pos = 0;

    while ((count == 0 || replacements < count)
            && pattern->Match(input, pos, input.size(), re2::RE2::UNANCHORED,
                    matches.data(), match_count)) {
        const int match_start = matches[0].data() - input.data();
        const int match_end = match_start + matches[0].size();
        output->append(input.data() + pos, match_start - pos);
        if (!pattern->Rewrite(output, rewrite, matches.data(), match_count)) {
            return -1;
        }
        pos = match_end;
        ++replacements;
    }
    output->append(input.data() + pos, input.size() - pos);
    return replacements;
}

struct re2_offset_slot {
    int offset;
    int slot;

    bool operator<(const re2_offset_slot& other) const
    {
        return offset < other.offset;
    }
};

static inline void re2_unicode_indices(
        int *offsets, int count, const char *string, int size,
        int *byte_pos, int *unicode_pos)
{
    const unsigned char *data =
            reinterpret_cast<const unsigned char *>(string);
    std::vector<re2_offset_slot> positions;
    positions.reserve(count);

    for (int slot = 0; slot < count; ++slot) {
        if (offsets[slot] < 0) {
            offsets[slot] = -1;
        } else {
            positions.push_back({offsets[slot], slot});
        }
    }
    std::sort(positions.begin(), positions.end());

    for (const re2_offset_slot& position : positions) {
        while (*byte_pos < position.offset && *byte_pos < size) {
            if (data[*byte_pos] < 0x80) {
                *byte_pos += 1;
            } else if (data[*byte_pos] < 0xe0) {
                *byte_pos += 2;
            } else if (data[*byte_pos] < 0xf0) {
                *byte_pos += 3;
            } else {
                *byte_pos += 4;
            }
            *unicode_pos += 1;
        }
        offsets[position.slot] = *unicode_pos;
    }
}

static inline void re2_unicode_index_pair(
        int *start, int *end, const char *string, int size,
        int *byte_pos, int *unicode_pos)
{
    const unsigned char *data =
            reinterpret_cast<const unsigned char *>(string);
    const int byte_start = *start;
    const int byte_end = *end;
    int unicode_start = *unicode_pos;

    while (*byte_pos < byte_end && *byte_pos < size) {
        if (*byte_pos == byte_start) {
            unicode_start = *unicode_pos;
        }
        if (data[*byte_pos] < 0x80) {
            *byte_pos += 1;
        } else if (data[*byte_pos] < 0xe0) {
            *byte_pos += 2;
        } else if (data[*byte_pos] < 0xf0) {
            *byte_pos += 3;
        } else {
            *byte_pos += 4;
        }
        *unicode_pos += 1;
    }
    if (byte_start == byte_end) {
        unicode_start = *unicode_pos;
    }
    *start = unicode_start;
    *end = *unicode_pos;
}

#endif
