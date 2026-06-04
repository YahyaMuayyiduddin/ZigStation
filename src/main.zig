const std = @import("std");
const Io = std.Io;

const ZigStation = @import("ZigStation");
// const cpu = @import("core/cpu/cpu.zig");

const SR = packed struct (u32) {
    IEc: bool,
    KUc: bool,
    IEp: bool,
    KUp: bool,
    IEo: bool,
    KUo: bool,
    pad0 : u2,
    IM: u8,
    IsC: bool,
    SwC: bool,
    PZ: bool,
    CM: bool,
    PE: bool,
    TS: bool,
    BEV: bool,
    pad1 : u2,
    RE: bool,
    pad2: u2,
    CU0: bool,
    CU1: bool,
    CU2: bool,
    CU3: bool
};


pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    std.debug.print("Size of sr: {}. \n", .{@sizeOf(SR)});
    // const k: u32 = @bitCast(@as(i16, @bitCast(@as(u16,0xFFFF))));



    const k: i8 = @bitCast(@as(u8, 0xFF));
    const shift: u2 = 3;
    const j: i8 = k >> (3 - shift + 1);
    const m: u8 = @bitCast(j);
    std.debug.print("{}\n",.{m});
    // const i: u8 = 0xFF << 2;

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try ZigStation.printAnotherMessage(stdout_writer);

    try stdout_writer.flush(); // Don't forget to flush!
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
