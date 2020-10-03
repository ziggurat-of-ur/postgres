const std = @import("std");
const mem = std.mem;

pub fn main() anyerror!void {
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
