// std
const std = @import("std");

const stdout = std.io.getStdOut();
const stdin = std.io.getStdIn();

pub const c_string = [*:0]const u8;

// use a static buffer for all the input
var cmdBuffer: [1024:0]u8 = undefined;

// read into the cmdBuffer and return it as a c_string
pub fn read() c_string {
    std.mem.set(u8, cmdBuffer[0..], 0x00);
    const input = stdin.reader().readUntilDelimiterOrEof(cmdBuffer[0..], '\n') catch |err| {
        std.debug.print("error: read from STDIN: {}\n", .{err});
        return "";
    } orelse return "";
    return cmdBuffer[0..];
}

// read with prompt
pub fn prompt(comptime fmt: []const u8, args: anytype) anyerror!c_string {
    try stdout.writer().print(fmt, args);
    return read();
}
