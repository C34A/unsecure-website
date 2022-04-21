const std = @import("std");
const Address = std.net.Address;
const routez =  @import("routez");
const sqlite = @import("sqlite");

const allocator = std.heap.page_allocator;

const io_mode = .evented;

pub fn main() anyerror!void {
    var server = routez.Server.init(
        allocator,
        .{},
        .{
            routez.all("/", indexHandler),
            routez.all("/msgs", getMessages),
            // get("/about", aboutHandler),
            // get("/about/more", aboutHandler2),
            // get("/post/{post_num}/?", postHandler),
            // static("./", "/static"),
            // all("/counter", counterHandler),
        }
    );
    var addr = try Address.parseIp("127.0.0.1", 8000);
    try server.listen(addr);
}

fn indexHandler(req: routez.Request, res: routez.Response) !void {
    _ = req;
    try res.sendFile("public/index.html");
}

/// Get all of the messages. example response:
/// [
///   {
///     "sender": "test_user",
///     "message": "this is an initial message in the db"
///   },
///   {
///     "sender": "test_user2",
///     "message": "this is another message"
///   }
/// ]
fn getMessages(req: routez.Request, res: routez.Response) !void {
    _ = req;

    try res.setType("application/json");
    
    var db = try getDB();

    // build DB command with query
    const query =
        \\SELECT sender, message, timestamp from Messages
    ;
    var diags = sqlite.Diagnostics{}; // magic beans
    var stmt = db.prepareWithDiags(query, .{.diags = &diags}) catch |err| {
        std.log.err("unable to prepare statement, got error {s}. diagnostics: {s}", .{err, diags});
        return err;
    };
    defer stmt.deinit();

    // This is what we hope to get from the db. i think sqlite-zig panics
    // if the data doesn't match this type.
    const MsgItem = struct {
        sender: []const u8,
        message: []const u8,
        timestamp: []const u8 // datetime
    };
    var iter = try stmt.iterator(MsgItem, .{});

    // arena to manage the iterator's allocations
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    
    var arr = std.ArrayList(MsgItem).init(arena.allocator());

    // loop through the iterator to get all entries
    while (true) {
        const obj = (try iter.nextAlloc(arena.allocator(), .{})) orelse break;
        try arr.append(obj);
    }
    
    // write data as json array into response body
    try std.json.stringify(arr.items, .{}, res.body);
}

inline fn getDB() !sqlite.Db {
    return sqlite.Db.init(sqlite.InitOptions{
        .mode = sqlite.Db.Mode{.File = "./db.db"},
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });
}