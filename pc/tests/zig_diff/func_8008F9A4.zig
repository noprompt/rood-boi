//! zig_diff spec: func_8008F9A4 -> func_8008F9A4.func_8008F9A4 (146C.c).
//! Inputs: a loop count from -2^31 and -3..40 (no huge counts: each stub call
//! hashes the whole state, and a wrapping i16 store needs more than 32767
//! calls), so the loop runs 0, 1 or many times. The table pointer
//! D_800F1DD4 is an arena array of max(count, 1) elements, or null when the
//! loop cannot run. The callee is a recording stub that writes the element
//! it is given, so the element bytes the C leaves behind are compared too.
//! The stub ignores a null element, so a mutant that calls it on a null
//! table is reported as a mismatch, not a panic in the stub.
//! arg1 is random: it only reaches the u8 store.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008F9A4));

pub const classes = [_][:0]const u8{ "no-loop", "one-call", "many-calls" };

pub const stubs = struct {
    pub fn func_8008FA14(ctx: *zd.Ctx, p: anytype) void {
        if (@intFromPtr(p) == 0) return;
        const e: *v.D_800F1DD4_t = @ptrCast(@alignCast(p));
        e.unk0 = ctx.value(i16);
        e.unkC = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const n: c_int = if (ctx.chance(5))
        ctx.edge(c_int, &.{ -2147483648, -1, 0 })
    else
        ctx.range(c_int, -3, 40);
    const count: usize = if (n > 0) @intCast(n) else 1;
    const elems: [*]v.D_800F1DD4_t = @ptrCast(@alignCast(ctx.allocBytes(count * @sizeOf(v.D_800F1DD4_t), 16)));
    if (n <= 0 and ctx.chance(2)) {
        v.g.D_800F1DD4().* = null;
    } else {
        v.g.D_800F1DD4().* = &elems[0];
    }
    return .{ n, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const n = args[0];
    if (n <= 0) return 0;
    if (n == 1) return 1;
    return 2;
}
