//! zig_diff spec: func_8008F29C -> func_8008F29C.func_8008F29C (146C.c).
//! Inputs: arg0 is the loop count: no calls (<= 0), one call, several calls,
//! and values a byte cannot hold (259 stores differently from a byte, and
//! -32769 or -65537 wrap in the i16 stores without a loop). arg1 is the value
//! stored as a byte, with bit 7, 0, 255, 256, -1 and the extremes included.
//! D_800F1DD4 points at a 512-element arena block. The callee is a recording
//! stub that sometimes rewrites the element it is passed (when that element
//! lies in the arena) and sometimes D_800F1DC0, which the C does not re-read.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008F29C));

pub const classes = [_][:0]const u8{ "no-calls", "one-call", "many-calls", "over-byte" };

pub const stubs = struct {
    pub fn func_80090A1C(ctx: *zd.Ctx, p: anytype) void {
        const base = @intFromPtr(&zd.zdiff_arena);
        const a = @intFromPtr(p);
        if (a >= base and a + @sizeOf(v.D_800F1DD4_t) <= base + zd.arena_size and ctx.value(u1) == 1) {
            const e: *v.D_800F1DD4_t = @ptrFromInt(a);
            e.unk0 = ctx.value(i16);
            e.unkC = ctx.value(u8);
        }
        if (ctx.value(u1) == 1) v.g.D_800F1DC0().* = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const block: [*]v.D_800F1DD4_t = @ptrCast(@alignCast(ctx.allocBytes(512 * @sizeOf(v.D_800F1DD4_t), 16)));
    v.g.D_800F1DD4().* = &block[0];
    const arg0: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ -65537, -32769, -32768, -2, -1, 0, 1, 259 })
    else
        ctx.range(c_int, -1, 8);
    const arg1: c_int = ctx.pick(c_int, &.{ 0, 1, 127, 128, 255, 256, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const n = args[0];
    if (n > 255 or n < -32768) return 3;
    if (n <= 0) return 0;
    if (n == 1) return 1;
    return 2;
}
