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

const expect = std.testing.expect;

test "blah" {
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