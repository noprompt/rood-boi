//! zig_diff spec: func_8008C40C -> func_8008C40C.func_8008C40C (146C.c).
//! Inputs: vs_battle_roomData.geometrySection is null (the C's guard skips the
//! loop), or points at a geometry block in the arena whose count word at [0]
//! is 0, -1, INT_MIN, 1, or 2..1500. The block's other words keep the random
//! fill, so bit 12 of every entry is set or clear at random. The block holds
//! 64 bytes per count entry plus slack, so the C's 16-word stride stays inside
//! memory the harness owns.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C40C));

pub const classes = [_][:0]const u8{ "null", "empty", "run" };

/// Writes a psx_ptr field's 4-byte guest address.
fn setRaw(field: anytype, raw: u32) void {
    @as(*align(1) u32, @ptrCast(field)).* = raw;
}

fn rawOf(field: anytype) u32 {
    return @as(*align(1) const u32, @ptrCast(field)).*;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    if (ctx.range(u8, 0, 9) == 0) {
        setRaw(&room.geometrySection, 0);
        return .{};
    }
    const count: i32 = switch (ctx.range(u8, 0, 9)) {
        0 => 0,
        1 => -1,
        2 => std.math.minInt(i32),
        3 => 1,
        else => ctx.range(i32, 2, 1500),
    };
    const n: usize = if (count > 0) @intCast(count) else 0;
    const block = ctx.allocBytes(64 * n + 64, 16);
    const words: [*]i32 = @ptrCast(@alignCast(block));
    words[0] = count;
    setRaw(&room.geometrySection, psx.addr(words));
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const room = v.g.vs_battle_roomData();
    const raw = rawOf(&room.geometrySection);
    if (raw == 0) return 0;
    const count = @as(*const i32, @ptrFromInt(raw)).*;
    return if (count <= 0) 1 else 2;
}
