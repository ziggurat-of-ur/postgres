// std
const std = @import("std");
const mem = std.mem;

// clap for CLI args
const clap = @import("clap");

// postgres wrapper
const pq = @import("postgres");

/// getParams constructs the PG connection params from the CLI args
fn getParams() anyerror!pq.ConnectionParams {
    var conn = pq.ConnectionParams{};

    // Parse the CLI args into the ConnectionParams
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --host <STR>         Set hostname, default = localhost.") catch unreachable,
        clap.parseParam("-U, --username <STR>     Set username, default = postgres.") catch unreachable,
        clap.parseParam("-d, --dbname <STR>       Set Database name.") catch unreachable,
        clap.Param(clap.Help){
            .takes_value = .One,
        },
    };

    var args = try clap.parse(clap.Help, &params, std.heap.page_allocator);
    defer args.deinit();

    if (args.option("-h")) |hostname| {
        conn.hostname = hostname;
    }
    if (args.option("--username")) |username| {
        conn.username = username;
    }
    if (args.option("--dbname")) |dbname| {
        conn.dbname = dbname;
    }
    return conn;
}

pub fn main() anyerror!void {
    std.debug.print("Using PG wrapper {}\n", .{pq.version});

    var params = try getParams();
    var dsn = try params.dsn();
    var db = try pq.connect(dsn);
    std.debug.print("DB connection {}\n", .{db});

    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();
    var buffer: [1024]u8 = undefined;

    // just loop forever, getting a command, executing it, and then quitting when the user types \q
    while (true) {
        mem.set(u8, buffer[0..], 0x00);
        try stdout.writer().print("ZSQL: ", .{});

        const raw_input = stdin.reader().readUntilDelimiterOrEof(buffer[0..], '\n') catch |err| {
            std.debug.print("error: cannot read from STDIN: {}\n", .{err});
            return;
        } orelse return;
        const input = mem.trimRight(u8, raw_input, "\r\n");
        if (mem.eql(u8, input, "\\q")) {
            return;
        }
        std.debug.print("Exec command '{}'\n", .{input});
        db.exec(input);
    }
}
