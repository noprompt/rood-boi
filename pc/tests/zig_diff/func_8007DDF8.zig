//! zig_diff spec: func_8007DDF8 -> func_8007DDF8.func_8007DDF8 (146C.c).
//! Inputs: a D_800F1A68_t in the arena, each field an edge value (0, +-1,
//! 16-bit and 32-bit extremes) or any i32, and the global either random or
//! already equal to the source (a no-op copy), so a dropped or partial copy
//! shows in both classes. The C has no branches; the copy and its fields are
//! what the mutations test.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DDF8));

pub const classes = [_][:0]const u8{ "already-equal", "differs" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const src = ctx.alloc(v.D_800F1A68_t);
    const edges = [_]i32{ 0, 1, -1, 0x7fff, -0x8000, 0x7fffffff, -0x80000000 };
    src.unk0 = ctx.pick(i32, &edges);
    src.unk4 = ctx.pick(i32, &edges);
    src.unk8 = ctx.pick(i32, &edges);
    src.unkC = ctx.pick(i32, &edges);
    // Sometimes the global already holds the source: the copy changes nothing.
    if (ctx.chance(4)) v.g.D_800F1A68().* = src.*;
    return .{src};
}

pub fn classify(args: Args) usize {
    const src = args[0].?;
    const same = std.mem.eql(u8, std.mem.asBytes(src), std.mem.asBytes(v.g.D_800F1A68()));
    return if (same) 0 else 1;
}
