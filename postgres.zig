const std = @import("std");
const pq = @cImport({
    @cInclude("libpq-fe.h");
});

pub const version = "0.0.1";

pub const string = []const u8;
pub const c_string = [*:0]const u8;

pub const Connection = struct {
    const Impl = @Type(.Opaque);
    impl: *Impl,
    pub fn exec(self: *Connection, cmd: string) void {
        std.debug.print("Exec: {}\n", .{cmd});
    }
};

pub const ConnectionParams = struct {
    hostname: string = "localhost",
    username: string = "postgres",
    dbname: string = "",
    pub fn dsn(self: *ConnectionParams) !c_string {
        const value = try std.fmt.allocPrint0(
            std.heap.page_allocator,
            "host: {}",
            .{self.hostname},
        );
        return value;
    }
};

pub fn connect(dsn: c_string) anyerror!Connection {
    var conn = pq.PQconnectdb(dsn);
    const allocator = std.heap.page_allocator;
    const cx = try allocator.alloc(Connection, 1);
    return cx[0];
}
