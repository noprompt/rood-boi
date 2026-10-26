//! zig_diff spec: func_80072EC4 -> func_80072EC4.func_80072EC4 (146C.c).
//! Inputs: a D_800F19CC_t in the arena (the global points at it), 16 actors in
//! the vs_battle_actors table, and arg0 either 0 (the player: the unk2984
//! branches and the arg0 == 0 call) or 1..15 (the loop skips one slot). arg1
//! takes the u16 edges. The bit test on func_800A0BE0's result sees bit 2 set
//! and clear, with and without the sign bit. func_8009E5C4 sets unk2984 to 0
//! or 1, so both flag branches run for either arg0. vs_main_bzero zeroes its
//! range as the real one does.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80072EC4));

pub const classes = [_][:0]const u8{ "target-zero", "target-nonzero" };

pub const stubs = struct {
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const q: ?*anyopaque = p;
        const bytes: [*]u8 = @ptrCast(q.?);
        @memset(bytes[0..@intCast(n)], 0);
    }

    pub fn func_8009E5C4(ctx: *zd.Ctx, id: anytype) void {
        _ = id;
        const d = v.g.D_800F19CC().*.?;
        // The C reads unk2984 back after this call.
        d.unk2984 = @as(i32, ctx.value(u1));
    }

    pub fn func_800A0BE0(ctx: *zd.Ctx, i: anytype) u32 {
        _ = i;
        // The C tests bit 2 of this result: both values occur.
        return ctx.value(u32);
    }

    pub fn func_8008B4C8(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    const table = v.g.vs_battle_actors();
    for (0..16) |i| table[i] = ctx.alloc(v.vs_battle_actor);
    const arg0: c_int = if (ctx.chance(4)) 0 else ctx.range(c_int, 1, 15);
    const arg1 = ctx.pick(c_ushort, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    return if (args[0] == 0) 0 else 1;
}
