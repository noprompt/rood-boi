//! zig_diff spec: vs_battle_getMapCompletion -> get_map_completion.getMapCompletion (146C.c).
//! Inputs: the map status room flags (random, with bit 23 of room 1 forced on or
//! off in turn, and every room flag set in some runs) and the 25-entry completion
//! table (random bits, all set, or the first 16 entries all zero). The C takes no
//! arguments and calls nothing; the result is the count of set completion bits
//! scaled to 0..141.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getMapCompletion));

pub const classes = [_][:0]const u8{ "table-zero", "bit23-set", "bit23-clear" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const s = v.g.vs_main_mapStatus();
    const table = v.g.vs_battle_mapCompletionFlags();

    // Bit 23 of room 1 (the C's first test) on and off, by turns.
    if (ctx.chance(2)) {
        s.roomFlags[1] |= 0x800000;
    } else {
        s.roomFlags[1] &= ~@as(i32, 0x800000);
    }

    // Every room flag set: the count reaches its maximum.
    if (ctx.chance(6)) {
        for (0..16) |i| s.roomFlags[i] = -1;
    }

    // Completion table: all zero (count 0), all set, or random bits.
    if (ctx.chance(8)) {
        for (0..16) |i| table[i] = 0;
    } else if (ctx.chance(6)) {
        for (0..16) |i| table[i] = -1;
    }

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const table = v.g.vs_battle_mapCompletionFlags();
    var zero = true;
    for (0..16) |i| {
        if (table[i] != 0) zero = false;
    }
    if (zero) return 0;
    const s = v.g.vs_main_mapStatus();
    return if ((s.roomFlags[1] & 0x800000) != 0) 1 else 2;
}
