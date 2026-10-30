//! zig_diff spec: vs_battle_getStatusFlags -> get_status_flags.getStatusFlags (5BF94.c).
//! Inputs: an actor in the arena whose statuses word is random or one of
//! the edges (zero, all ones, the sign bit alone, the status-flag bits 21-28
//! alone or all set), so the flag byte covers no flags, one flag, several
//! flags and all flags, and the sign bit is set about half the time (the
//! u_int read). The eight D_800EBC68 entries are random or edges (0, 1,
//! 0x7FFF, 0x8000, 0xFFFF), so the shifted OR sets the sign bit when an
//! entry is 0x8000 or more. The C calls no function, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getStatusFlags));

pub const classes = [_][:0]const u8{ "no-flags", "one-flag", "several-flags", "all-flags" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor2);
    actor.statuses = ctx.pick(i32, &.{
        0,
        -1,
        std.math.minInt(i32),
        std.math.maxInt(i32),
        0x00200000,
        0x1FE00000,
        0x0FE00000,
        0x7FE00000,
        0x00040000,
    });
    const d = v.g.D_800EBC68();
    for (0..8) |i| {
        d[i] = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    }
    return .{actor};
}

pub fn classify(args: Args) usize {
    const bits: u32 = (@as(u32, @bitCast(args[0].?.statuses)) >> 21) & 0xFF;
    if (bits == 0) return 0;
    if (bits == 0xFF) return 3;
    if (@popCount(bits) == 1) return 1;
    return 2;
}
