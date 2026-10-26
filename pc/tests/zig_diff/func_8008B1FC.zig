//! zig_diff spec: func_8008B1FC -> func_8008B1FC.func_8008B1FC (146C.c).
//! Inputs: an optional opaque object for arg0 (null or an arena block; the
//! C never dereferences it, the callees are recording stubs) and the
//! D_800F1BB0 block's unk6 field in four classes: zero, the sign bit set
//! (-32768 and -1), and positive. The scratchpad word at 0x1F800000 and
//! D_800F19C8 are random. The stubs of func_800983F8 and func_8009723C
//! rewrite the scratchpad word the C reads back, and func_8009723C also
//! rewrites unk6, which the C tests after that call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B1FC));

pub const classes = [_][:0]const u8{ "unk6-zero", "unk6-negative", "unk6-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const blk = v.g.D_800F1BB0();
    blk.unk6 = switch (ctx.range(u8, 0, 4)) {
        0 => 0,
        1 => -32768,
        2 => -1,
        3 => 1,
        else => ctx.int(i16),
    };
    const obj: ?*anyopaque = if (ctx.chance(4)) null else @ptrCast(ctx.alloc(v.MATRIX));
    return .{obj};
}

pub fn classify(args: Args) usize {
    _ = args;
    const u = v.g.D_800F1BB0().unk6;
    if (u == 0) return 0;
    return if (u < 0) 1 else 2;
}

fn setScratch(ctx: *zd.Ctx) void {
    @as(*u32, @ptrFromInt(zd.scratchpad)).* = ctx.value(u32);
}

pub const stubs = struct {
    pub fn func_800983F8(ctx: *zd.Ctx, p: anytype) void {
        _ = p;
        if (ctx.value(u1) == 1) setScratch(ctx);
    }

    pub fn func_8009723C(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = p;
        _ = n;
        if (ctx.value(u1) == 1) setScratch(ctx);
        if (ctx.value(u1) == 1) v.g.D_800F1BB0().unk6 = ctx.value(i16);
    }

    pub fn func_80098D6C(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        if (ctx.value(u1) == 1) setScratch(ctx);
    }
};
