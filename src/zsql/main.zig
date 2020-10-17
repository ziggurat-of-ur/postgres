// std
const std = @import("std");

const c_string = [*:0]const u8;

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
    var db = pq.connect(dsn) orelse {
        std.debug.print("Error connecting to db {}", .{dsn});
        return;
    };
    var db_name = db.name();

    // just loop forever, getting a command, executing it, and then quitting when the user types \q
    while (true) {
        var input = try cmd.prompt("ZSQL ({}): ", .{db.name()});

        if (hasPrefix("\\q", input)) {
            return;
        }
        if (hasPrefix("\\c ", input)) {
            const len = std.mem.len(input);
            params.dbname = input[3..len];
            dsn = try params.dsn();
            db = pq.connect(dsn) orelse {
                std.debug.print("Error connecting to db {}", .{dsn});
                return;
            };
            std.debug.print("new connection {}\n", .{db});
            continue;
        }

        var res = db.exec(input);
        var status = res.status();
        switch (status) {
            pq.ExecStatusType.PGRES_TUPLES_OK => {
                const tuples = res.numTuples();
                const flds = res.numFields();
                var i: u8 = 0;
                var fld: u8 = 0;
                while (fld < flds) : (fld += 1) {
                    std.debug.print("{} ", .{res.fieldName(fld)});
                }
                std.debug.print("\n------------------------------------------------------------------\n", .{});
                while (i < tuples) : (i += 1) {
                    fld = 0;
                    while (fld < flds) : (fld += 1) {
                        std.debug.print("{} ", .{res.get(i, fld)});
                    }
                    std.debug.print("\n", .{});
                }
                std.debug.print("Status: {}\n", .{res.cmdStatus()});
                std.debug.print("OK\n", .{});
            },
            else => std.debug.print("Status: {}\n", .{status}),
        }
        res.clear();
    }
}

fn hasPrefix(needle: c_string, haystack: c_string) bool {
    var index: usize = 0;
    while (needle[index] == haystack[index] and needle[index] != 0) : (index += 1) {}
    if (needle[index] == 0) {
        return true;
    }
    return false;
}
