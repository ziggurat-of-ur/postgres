// std
const std = @import("std");
const mem = std.mem;
const debug = std.debug;

// clap for CLI args
const clap = @import("clap");

// postgres wrapper
const pg = @import("postgres");

pub fn main() anyerror!void {
    debug.print("Using PG wrapper {}\n", .{pg.version});

    // First we specify what parameters our program can take.
    // We can use `parseParam` to parse a string to a `Param(Help)`
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --host <STR>         Set hostname, default = localhost.") catch unreachable,
        clap.parseParam("-U, --username <STR>     Set username, default = postgres.") catch unreachable,
        clap.parseParam("-d, --dbname <STR>       Set Database name.") catch unreachable,
        clap.Param(clap.Help){
            .takes_value = .One,
        },
    };

    var pgArgs = pg.connection{};
    var args = try clap.parse(clap.Help, &params, std.heap.page_allocator);
    defer args.deinit();

    if (args.option("--host")) |hostname| {
        debug.warn("--host {}\n", .{hostname});
        pgArgs.hostname = hostname;
    }
    if (args.option("--username")) |username| {
        debug.warn("--username = {}\n", .{username});
        pgArgs.username = username;
    }
    if (args.option("--dbname")) |dbname| {
        debug.warn("--dbname = {}\n", .{dbname});
        pgArgs.dbname = dbname;
    }
    for (args.positionals()) |pos|
        debug.warn("{}\n", .{pos});

    debug.print("args {}\n", .{pgArgs});
    try cmdLoop();
}

fn cmdLoop() anyerror!void {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();
    var buffer: [1024]u8 = undefined;

    // just loop forever, getting a command, executing it, and then quitting when the user types \q
    while (true) {
        try stdout.writer().print("ZSQL: ", .{});

        const raw_input = stdin.reader().readUntilDelimiterOrEof(buffer[0..], '\n') catch |err| {
            std.debug.print("error: cannot read from STDIN: {}\n", .{err});
            return;
        } orelse return;
        const input = mem.trimRight(u8, raw_input, "\r\n");
        if (mem.eql(u8, input, "\\q")) {
            return;
        }
        std.debug.print("Error: Unknown command '{}'\n", .{input});
    }
}
