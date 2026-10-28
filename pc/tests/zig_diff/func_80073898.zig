//! zig_diff spec: func_80073898 -> func_80073898.func_80073898 (146C.c).
//! Inputs: the value func_800BEB10 returns (a c_short), drawn half from edges
//! (0, 1, -1, -32768, 32767, 0x4000) and half from any i16, so both sides of
//! `(x << 16) != 0` are taken, with and without the sign bit. func_800BEB10
//! returns that value; func_80073870 is a recording stub that writes the two
//! globals it could touch, which the state comparison then covers.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073898));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

/// The value func_800BEB10 returns in this iteration (the same in both runs).
var ret: c_short = 0;

pub const stubs = struct {
    pub fn func_800BEB10(ctx: *zd.Ctx) c_short {
        _ = ctx;
        return ret;
    }

    pub fn func_80073870(ctx: *zd.Ctx) void {
        v.g.D_800F196C().* = ctx.value(u32);
        v.g._cameraMode().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    ret = ctx.pick(c_short, &.{ 0, 1, -1, -32768, 32767, 0x4000 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (ret == 0) return 0;
    return if (ret < 0) 1 else 2;
}
