//! zig_diff spec: func_800780A8 -> func_800780A8.func_800780A8 (146C.c).
//! Inputs: arg0 is an arena SVECTOR; the global D_800F19CC points at an arena
//! D_800F19CC_t whose unk0 selects one of the four unk854 slots (0-3). The slot's
//! unk4A is zero or a value with and without the sign bit, and its unk4C[0].unk40
//! is zero, positive, negative or the INT_MIN edge. That covers the three paths:
//! the unk844 copy, the func_80077F14 call, and the raw 8-byte copy of unk4C[0].unk0.
//! The two callees write their out-parameters with ctx.value (full i16 range, so
//! the differences wrap and the halving truncates negative odd values).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800780A8));

pub const classes = [_][:0]const u8{ "copy-unk844", "call-80077F14", "copy-raw-unk4C" };

pub const stubs = struct {
    pub fn func_800A1AF8(ctx: *zd.Ctx, a: anytype, b: anytype, out: anytype, d: anytype) void {
        _ = a;
        _ = b;
        _ = d;
        const s: *v.SVECTOR = @ptrCast(@alignCast(out));
        s.vx = ctx.value(i16);
        s.vy = ctx.value(i16);
        s.vz = ctx.value(i16);
        s.pad = ctx.value(i16);
    }
    pub fn func_80077F14(ctx: *zd.Ctx, actor: anytype, limb: anytype, out: anytype) void {
        _ = actor;
        _ = limb;
        const s: *v.SVECTOR = @ptrCast(@alignCast(out));
        s.vx = ctx.value(i16);
        s.vy = ctx.value(i16);
        s.vz = ctx.value(i16);
        s.pad = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const out = ctx.alloc(v.SVECTOR);
    const data = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = data;
    data.unk0 = ctx.edge(u32, &.{ 0, 1, 2, 3 });
    const t = &data.unk854[data.unk0];
    t.unk4A = if (ctx.chance(4)) 0 else ctx.pick(u16, &.{ 1, 0x7FFF, 0x8000, 0xFFFF });
    t.unk4C[0].unk40 = ctx.pick(i32, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{out};
}

pub fn classify(args: Args) usize {
    _ = args;
    const data = v.g.D_800F19CC().*.?;
    const t = &data.unk854[data.unk0];
    if (t.unk4A == 0) return 0;
    if (t.unk4C[0].unk40 == 0) return 1;
    return 2;
}
