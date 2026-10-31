//! zig_diff spec: func_800D169C -> func_800D169C.func_800D169C (5BF94.c).
//! Inputs: three SVECTOR objects in the arena, with each component an edge
//! value (0, +-1, the i16 extremes) or any i16, and arg2 an edge value or any
//! c_int. arg3 is arg0, arg1 or a fresh object, and arg0 is sometimes arg1,
//! so the aliasing cases (arg3 == arg0, arg3 == arg1, arg0 == arg1) all occur.
//! vs_battle_lerp takes its operands by value and touches no state; its stub
//! returns any c_int, so the i16 narrowing of each result is exercised.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_800D169C));

pub const classes = [_][:0]const u8{ "distinct", "arg3-is-arg0", "arg3-is-arg1", "arg0-is-arg1" };

pub const stubs = struct {
    /// Pure: it reads its operands by value and changes no state. It returns
    /// any c_int, which the C narrows into the i16 component.
    pub fn vs_battle_lerp(ctx: *zd.Ctx, a: anytype, b: anytype, t: anytype) c_int {
        _ = a;
        _ = b;
        _ = t;
        return ctx.value(c_int);
    }
};

const edges = [_]i16{ 0, 1, -1, 32767, -32768, 256 };

fn fill(ctx: *zd.Ctx, p: *v.SVECTOR) void {
    p.vx = ctx.pick(i16, &edges);
    p.vy = ctx.pick(i16, &edges);
    p.vz = ctx.pick(i16, &edges);
    p.pad = ctx.int(i16);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.alloc(v.SVECTOR);
    fill(ctx, a0);
    const a1 = if (ctx.chance(4)) a0 else blk: {
        const p = ctx.alloc(v.SVECTOR);
        fill(ctx, p);
        break :blk p;
    };
    const a3 = switch (ctx.int(u2)) {
        0 => a0,
        1 => a1,
        else => blk: {
            const p = ctx.alloc(v.SVECTOR);
            fill(ctx, p);
            break :blk p;
        },
    };
    const arg2 = ctx.pick(c_int, &.{ 0, 1, -1, 4096, 65536, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{ a0, a1, arg2, a3 };
}

pub fn classify(args: Args) usize {
    if (args[3] == args[0]) return 1;
    if (args[3] == args[1]) return 2;
    if (args[0] == args[1]) return 3;
    return 0;
}
