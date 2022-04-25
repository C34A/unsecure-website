const std = @import("std");

///https://www.eso.org/~ndelmott/url_encode.html
const table: [128]?u8 =
    [_]?u8{'\x00'} ++
    [_]?u8{null} ** 8 ++
    [_]?u8{'\t', '\n', null, null, '\r'} ++
    [_]?u8{null} ** 18 ++
    [_]?u8{
        ' ',
        '!',
        '"',
        '#',
        '$',
        '%',
        '&',
        '\'',
        '(',
        ')',
        '*',
        '+',
        ',',
        '-',
        '.',
        '/',
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        ':',
        ';',
        '<',
        '=',
        '>',
        '?',
        '@',
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
        '[',
        '\\',
        ']',
        '^',
        '_',
        '`',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'q',
        'x',
        'y',
        'z',
        '{',
        '|',
        '}',
        '~',
        ' ',
    };

/// Convert an ascii slice of % followed by two hex digits to the
/// equivalent ascii from url encoding.
pub fn to_ascii(encoded: []const u8) !?u8 {
    if(encoded.len != 3) {
        return URLEncodingError.BadInput;
    }
    const idx = try std.fmt.parseInt(u8, encoded[1..3], 16);
    if (idx > 0 and idx < (comptime (&table).len)) {
        return table[idx];
    }
    return null;
}

pub const URLEncodingError = error {
    IllegalCharacter,
    BadInput,
};

/// like to_ascii but fail instead of null
pub fn to_ascii_expect(encoded: []const u8) !u8 {
    return (try to_ascii(encoded)) orelse URLEncodingError.IllegalCharacter;
}

pub fn decode_str(str: []const u8, alloc: std.mem.Allocator) !std.ArrayList(u8) {
    var ret = std.ArrayList(u8).init(alloc);
    
    var i: usize = 0;
    while (i < str.len) {
        const c = str[i];
        if (c == '%') {
            if (i > str.len - 3) {
                // error or whatever
                return URLEncodingError.BadInput;
            }
            try ret.append(try to_ascii_expect(
                str[i..i+3]
            ));
            i += 3;
        } else {
            try ret.append(c);
            i += 1;
        }
    }
    return ret;
} 

/// Parse query parameters of format "key=value;key2=value2&key3=value3"...
/// returned map as well as keys and values are allocated with given allocator.
pub fn parse_query(allocator: std.mem.Allocator, query: []const u8) !std.StringHashMap([]const u8) {
    std.debug.print("query: {s}\n", .{query});
    var map = std.StringHashMap([]const u8).init(allocator);

    var start: usize = 0;
    var end: usize = 0;
    while (true) {
        if (query[end] == '=') {
            const key_name_slice = query[start..end];
            end += 1;
            start = end;
            // find end
            while (end < query.len and query[end] != ';' and query[end] != '&') {end += 1;}
            const value_slice = query[start..end];
            start = end + 1;
            end = start;

            std.debug.print("{{\n  k: '{s}'\n  v: '{s}'\n}}\n", .{key_name_slice, value_slice});

            var key = try decode_str(key_name_slice, allocator);
            var value = try decode_str(value_slice, allocator);
            try map.putNoClobber(key.toOwnedSlice(), value.toOwnedSlice());
        } else {
            end += 1;
        }
        if (end >= query.len) {
            break;
        }
    }
    return map;
}

const expect = std.testing.expect;

test "table alignment" {
    try expect(table[0].? == '\x00');
    try expect(table[0x11] == null);
    try expect(table[0x2b].? == '+');
    try expect(table[0x6d].? == 'm');
    try expect(table[0x7e].? == '~');
}

test "decode" {
    try expect((try to_ascii("%20")).? == ' ');
    try expect((try to_ascii("%91")) == null);
    try expect((try to_ascii("%7b")).? == '{');
}