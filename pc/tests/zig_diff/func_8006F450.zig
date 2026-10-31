//! zig_diff spec: func_8006F450 -> func_8006F450.func_8006F450 (146C.c).
//! Inputs: a random request object in the arena, with effectId and unk4 drawn
//! from edge values and otherwise any 16-bit value. The callee func_800CF3F8 is
//! a recording stub that copies the whole request it is passed into an arena
//! sink, so every byte the C writes into the request (and every byte of the
//! stack copy it does not write) is compared. The C has no branches; the two
//! classes split the inputs by whether the request already names effect 36.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F450));

pub const classes = [_][:0]const u8{ "effect-36", "other-effect" };

/// Where the stub copies the request it is passed (an arena object, compared).
var sink: ?*v.func_800CF0E8_t = null;

pub const stubs = struct {
    pub fn func_800CF3F8(ctx: *zd.Ctx, p: anytype, n: anytype) c_int {
        _ = n;
        if (sink) |s| {
            const src: *const v.func_800CF0E8_t = @ptrCast(@alignCast(p));
            s.* = src.*;
        }
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.func_800CF0E8_t);
    sink = ctx.alloc(v.func_800CF0E8_t);
    arg.effectId = ctx.pick(u16, &.{ 0, 1, 35, 36, 0x7FFF, 0x8000, 0xFFFF });
    arg.unk4 = ctx.pick(u16, &.{ 0, 1, 4, 0xFFFF });
    return .{arg};
}

pub fn classify(args: Args) usize {
    return if (args[0].?.effectId == 36) 0 else 1;
}
