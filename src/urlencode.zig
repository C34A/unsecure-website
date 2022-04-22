const std = @import("std");

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

pub fn to_ascii(encoded: *const [3]u8) !?u8 {
    const idx = try std.fmt.parseInt(u8, encoded[1..3], 16);
    if (idx > 0 and idx < (comptime (&table).len)) {
        return table[idx];
    }
    return null;
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