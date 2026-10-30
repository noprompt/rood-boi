//! zig_diff spec: func_8006B2D4 -> func_8006B2D4.func_8006B2D4 (146C.c).
//! Inputs: the character actor in the arena (its global set by prepare) with
//! a stats block (unk3C) that is always valid, and a statuses word drawn from
//! edges: zero, single bits around the 0x1E000000 mask, the mask itself, bit 0
//! alone, the sign bit with and without mask bits, and any random value. The
//! callees are recording stubs that rewrite the stats block's statuses, since
//! the C re-reads statuses after the first call and passes it to the second.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006B2D4));

pub const classes = [_][:0]const u8{ "mask-zero-sign-clear", "mask-zero-sign-set", "mask-set-sign-clear", "mask-set-sign-set" };

const sign_bit: i32 = @bitCast(@as(u32, 0x8000_0000));

var actor_obj: *v.vs_battle_actor = undefined;
var stats_obj: *v.vs_battle_actor2 = undefined;

pub const stubs = struct {
    pub fn func_80093FEC(ctx: *zd.Ctx, a: anytype, b: anytype, c_: anytype, d: anytype) void {
        _ = a;
        _ = b;
        _ = c_;
        _ = d;
        // The callee may rewrite the character's statuses; the C re-reads them.
        if (ctx.value(u1) == 1) stats_obj.statuses = ctx.value(i32);
    }

    pub fn func_80086754(ctx: *zd.Ctx, n: anytype, p: anytype) void {
        _ = n;
        // The callee may rewrite the statuses of the object it is passed.
        if (ctx.value(u1) == 1) {
            const a: *v.vs_battle_actor2 = @ptrCast(@alignCast(p));
            a.statuses = ctx.value(i32);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    actor_obj = actor;
    stats_obj = stats;
    psx.put(&actor.stats, stats);
    v.g.vs_battle_characterState().* = actor;
    stats.statuses = ctx.pick(i32, &[_]i32{
        0,
        1,
        0x0100_0000,
        0x0200_0000,
        0x0400_0000,
        0x0800_0000,
        0x1000_0000,
        0x1E00_0000,
        0x2000_0000,
        0x01FF_FFFF,
        sign_bit,
        sign_bit | 0x0100_0000,
        sign_bit | 0x1E00_0000,
        sign_bit | 0x0200_0000,
        -1,
    });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const s = stats_obj.statuses;
    const masked = s & 0x1E00_0000;
    return (if (masked != 0) @as(usize, 2) else 0) + (if (s < 0) @as(usize, 1) else 0);
}
