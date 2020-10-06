pub const version = "0.0.1";

const string = []const u8;

pub const connection = struct {
    hostname: string = "localhost",
    username: string = "postgres",
    dbname: string = "",
};
