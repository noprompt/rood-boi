//! zig_diff spec: func_800CC128 -> func_800CC128.func_800CC128 (5BF94.c).
//! Inputs: a gim_t in the arena whose unk3 is 0x80 (the early return) or any
//! other byte, including 0, 1, 0x7F, 0x81 and 0xFF, so 0x80 - unk3 crosses
//! zero; the frame buffer global zero, positive or negative, so both the sign
//! bit and the zero test are exercised; an arbitrary c_int for arg1; and a
//! primitive buffer in the arena. The func_800CBBCC stub sometimes rewrites
//! vs_main_frameBuf, which the C reads after that call. The setSprite stub
//! returns either a fresh arena block or the primitive buffer itself, so the
//! C's two stores can land in the same words.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CC128));

pub const classes = [_][:0]const u8{ "early-0x80", "frame-zero", "frame-negative", "frame-positive" };

pub const stubs = struct {
    pub fn func_800CBBCC(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) void {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        // The C reads vs_main_frameBuf after this call, so the real callee may change it.
        const k = ctx.value(u4);
        if (k == 0) {
            v.g.vs_main_frameBuf().* = 0;
        } else if (k == 1) {
            v.g.vs_main_frameBuf().* = ctx.value(i32);
        }
    }

    pub fn vs_battle_setSprite(ctx: *zd.Ctx, brightnessTransparency: anytype, xy: anytype, wh: anytype, nextPrim: anytype) [*c]c_uint {
        _ = brightnessTransparency;
        _ = xy;
        _ = wh;
        // The C stores through the returned pointer, so it must be valid.
        if (ctx.value(u1) == 1) return @ptrCast(@alignCast(nextPrim));
        return @ptrCast(@alignCast(ctx.allocBytes(16, 4)));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const gim = ctx.alloc(v.gim_t);
    const prim: [*c]c_uint = @ptrCast(@alignCast(ctx.allocBytes(32, 4)));

    gim.unk3 = if (ctx.chance(4)) 0x80 else ctx.pick(u8, &.{ 0, 1, 0x7F, 0x81, 0xFF });

    v.g.vs_main_frameBuf().* = if (ctx.chance(3))
        0
    else
        ctx.pick(i32, &.{ 1, -1, 0x140, 0x7FFFFFFF, -0x80000000 });

    const arg1 = ctx.pick(c_int, &.{ 0, 0x80, -1, 0x7FFFFFFF, -0x80000000 });
    return .{ gim, arg1, prim };
}

pub fn classify(args: Args) usize {
    const gim = args[0].?;
    if (gim.unk3 == 0x80) return 0;
    const frame = v.g.vs_main_frameBuf().*;
    if (frame == 0) return 1;
    if (frame < 0) return 2;
    return 3;
}
