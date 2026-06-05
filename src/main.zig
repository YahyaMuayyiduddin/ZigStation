const std = @import("std");
const Io = std.Io;

const ZigStation = @import("ZigStation");
// const cpu = @import("core/cpu/cpu.zig");
// const opcode = @import("core/cpu/opcodes.zig");


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

pub fn lol() i8 {
    const k: i8 = @bitCast(@as(u8, 0xFF));
    const shift: u2 = 3;
    const j: i8 = k >> (4 - shift );
    return j;
}

pub fn main(init: std.process.Init) !void {

    const k: u33 = 98;
    const l: u32 = 95;
    if (l >> 31 & 1 != (k >> 32) & 1){
        std.debug.print("cools", .{});
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

