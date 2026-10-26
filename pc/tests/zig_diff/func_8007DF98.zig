//! zig_diff spec: func_8007DF98 -> func_8007DF98.func_8007DF98 (146C.c).
//! Inputs: the 32-entry D_800F19A8 table, filled from edge bytes around 0xFE
//! and 0xFD in four modes: neither marker, 0xFE only, 0xFD only, both. Each
//! mode is reached often, so both tests of every entry go both ways, the loop
//! runs to its end, and an 0xFD entry is rewritten to 0xFE without being
//! tested again.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DF98));

pub const classes = [_][:0]const u8{ "neither", "fe-only", "fd-only", "both" };

const safe = [_]u8{ 0, 1, 0x7F, 0x80, 0xFA, 0xFC, 0xFF };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.D_800F19A8();
    const mode = ctx.range(u8, 0, 3);
    for (0..32) |i| {
        table[i] = ctx.edge(u8, &safe);
        if (mode & 1 != 0 and ctx.chance(6)) table[i] = 0xFE;
        if (mode & 2 != 0 and ctx.chance(6)) table[i] = 0xFD;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const table = v.g.D_800F19A8();
    var fe = false;
    var fd = false;
    for (0..32) |i| {
        if (table[i] == 0xFE) fe = true;
        if (table[i] == 0xFD) fd = true;
    }
    if (fe and fd) return 3;
    if (fd) return 2;
    if (fe) return 1;
    return 0;
}
