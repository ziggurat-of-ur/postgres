// std
const std = @import("std");
const cstr = std.cstr;

// clap for CLI args
const clap = @import("clap");

// cmd line getter
const cmd = @import("cmd");

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

    if (args.option("--host")) |hostname| {
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
    var db = pq.connect(dsn);
    var db_name = db.name();

    // just loop forever, getting a command, executing it, and then quitting when the user types \q
    while (true) {
        var input = try cmd.prompt("ZSQL ({}): ", .{db.name()});

        if (std.cstr.cmp(input, "\\q") == 0) {
            return;
        }

        var res = db.exec(input);
        var status = res.status();
        switch (status) {
            pq.ExecStatusType.PGRES_TUPLES_OK => {
                std.debug.print("OK\n", .{});
            },
            else => std.debug.print("Status: {}\n", .{status}),
        }
    }
}
