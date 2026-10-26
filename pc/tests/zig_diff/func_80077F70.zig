//! zig_diff spec: func_80077F70 -> func_80077F70.func_80077F70 (146C.c).
//! Inputs: the battle global D_800F19CC points at an arena object whose
//! current index unk0 is 0-3 (the entry unk854[unk0]). Its unk4A flag is
//! 0, 1, 2, 0x8000 or 0xFFFF (zero, small, and sign bit set), and its
//! unk4C[0].unk40 is 0, 1 or -1. Both external fetches are recording stubs
//! that write the out-vector with ctx.value, so the two endpoints differ
//! from the random scratch. The GTE rsqrt calls take the default stub.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80077F70));

pub const classes = [_][:0]const u8{ "unk4A-zero", "fetch-by-func", "copy-raw" };

pub const stubs = struct {
    pub fn func_800A1AF8(ctx: *zd.Ctx, actor: anytype, limb: anytype, out: anytype, flag: anytype) void {
        _ = actor;
        _ = limb;
        _ = flag;
        fillVector(ctx, out);
    }

    pub fn func_80077F14(ctx: *zd.Ctx, actor: anytype, limb: anytype, out: anytype) void {
        _ = actor;
        _ = limb;
        fillVector(ctx, out);
    }
};

fn fillVector(ctx: *zd.Ctx, out: anytype) void {
    const o: *v.SVECTOR = @ptrCast(@alignCast(out));
    o.vx = ctx.value(i16);
    o.vy = ctx.value(i16);
    o.vz = ctx.value(i16);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = obj;
    obj.unk0 = ctx.edge(u32, &.{ 0, 1, 2, 3 });
    const t = &obj.unk854[obj.unk0];
    t.unk4A = ctx.edge(u16, &.{ 0, 0, 1, 2, 0x8000, 0xFFFF });
    t.unk4C[0].unk40 = ctx.edge(i32, &.{ 0, 1, -1 });
    t.unk4.unk0.targetActor = ctx.int(u8);
    t.unk4.unk0.targetLimb = ctx.int(i8);
    t.unk4C[0].unk0.targetActor = ctx.int(u8);
    t.unk4C[0].unk0.targetLimb = ctx.int(i8);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const obj = v.g.D_800F19CC().*.?;
    const t = &obj.unk854[obj.unk0];
    if (t.unk4A == 0) return 0;
    if (t.unk4C[0].unk40 == 0) return 1;
    return 2;
}
