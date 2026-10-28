//! zig_diff spec: func_800782E4 -> func_800782E4.func_800782E4 (146C.c).
//! Inputs: a D_800F19CC_t in the arena, set as the global pointer. The gate
//! `unk2984` is zero, or nonzero with and without the sign bit. The target
//! byte is zero or nonzero (with and without the top bit), and the counter
//! `unk298E` is chosen around 30, 31 and the u8 wrap at 255, so `++` gives
//! v below, equal to, and above 0x1F. func_800C4794 returns 0 about 40% of
//! the time and a nonzero i32 (either sign) otherwise, and it writes its
//! SVECTOR argument. func_8007053C is a recording void stub.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800782E4));

pub const classes = [_][:0]const u8{ "gate-off", "target-zero", "counter-below", "counter-at", "counter-above" };

pub const stubs = struct {
    pub fn func_800C4794(ctx: *zd.Ctx, p: anytype) c_int {
        const sv: *v.SVECTOR = @ptrCast(@alignCast(p));
        sv.vx = ctx.value(i16);
        if (ctx.value(u8) < 100) return 0;
        const r = ctx.value(i32);
        return if (r == 0) -1 else r;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk2984 = ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32), 0x7FFF_FFFF });
    d.unk8.unk4.unk0.targetActor = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF });
    d.unk298E = ctx.pick(u8, &.{ 0, 29, 30, 31, 254, 255 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk2984 == 0) return 0;
    if (d.unk8.unk4.unk0.targetActor == 0) return 1;
    const nv: u8 = d.unk298E +% 1;
    if (nv < 0x1F) return 2;
    if (nv == 0x1F) return 3;
    return 4;
}
