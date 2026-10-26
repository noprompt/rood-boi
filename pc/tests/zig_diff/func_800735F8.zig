//! zig_diff spec: func_800735F8 -> func_800735F8.func_800735F8 (146C.c).
//! Inputs: an arg block whose unk2 selects the switch (5, 6-8, 10, or an
//! unmatched value such as 0, 9, 11, -1, the i16 extremes), a random
//! executeAbility (the s32 and the 13-bit MP cost), and an actor that is the
//! global vs_battle_characterState with a stats block whose currentMP is
//! below, equal to, or above the cost, including negative values. Stubs
//! model the case-10 out-parameter (sp18, 16 bytes), the fast-travel result
//! (zero and nonzero with and without the sign bit), and func_8007C694
//! changing currentMP before the C re-reads it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800735F8));

pub const classes = [_][:0]const u8{ "break-5", "call-6-8", "pay-short", "pay-equal", "pay-over", "default" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F18EC_t);
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    v.g.vs_battle_characterState().* = actor;
    psx.put(&actor.stats, stats);

    arg.unk2 = ctx.edge(i16, &.{ 5, 6, 7, 8, 10, 10, 0, 9, 11, -1, -32768, 32767 });
    const cost = ctx.int(u13);
    psx.setBits(&arg.executeAbility.fields, "unk0_19", cost);

    stats.currentMP = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    if (ctx.chance(3)) {
        stats.currentMP = @intCast(cost);
    } else if (ctx.chance(4)) {
        stats.currentMP = @intCast(@as(u16, cost) + 1);
    }
    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0].?;
    return switch (arg.unk2) {
        5 => 0,
        6, 7, 8 => 1,
        10 => blk: {
            const actor = v.g.vs_battle_characterState().*.?;
            const stats = psx.get(actor.stats).?;
            const cost: i32 = psx.getBits(&arg.executeAbility.fields, "unk0_19");
            const mp: i32 = stats.currentMP;
            if (mp < cost) break :blk 2;
            if (mp == cost) break :blk 3;
            break :blk 4;
        },
        else => 5,
    };
}

pub const stubs = struct {
    // Writes the 16-byte out-parameter (sp18) the C then reads through func_8006F4B0.
    pub fn func_800A1108(ctx: *zd.Ctx, a: anytype, out: anytype) c_int {
        _ = a;
        const bytes: [*]u8 = @ptrFromInt(@intFromPtr(out));
        for (0..16) |i| bytes[i] = ctx.value(u8);
        return ctx.value(c_int);
    }

    // Fast travel: zero half the time, otherwise a value with either sign.
    pub fn pc_fast_travel_begin(ctx: *zd.Ctx, p: anytype) c_int {
        _ = p;
        const r = ctx.value(i32);
        if (ctx.value(u2) == 0) return 0;
        return r;
    }

    // May change the MP the C re-reads after the call.
    pub fn func_8007C694(ctx: *zd.Ctx, p0: anytype, p1: anytype, p2: anytype, p3: anytype, p4: anytype) c_int {
        _ = .{ p0, p1, p2, p3, p4 };
        if (ctx.value(u1) == 1) {
            const actor = v.g.vs_battle_characterState().*.?;
            const stats = psx.get(actor.stats).?;
            stats.currentMP = ctx.value(i16);
        }
        return ctx.value(c_int);
    }
};
