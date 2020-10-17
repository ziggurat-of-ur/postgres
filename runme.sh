set -x
zig build
./zig-cache/bin/zsql -h postgres.local -d migrator
echo gdb ./zig-cache/bin/zsql
