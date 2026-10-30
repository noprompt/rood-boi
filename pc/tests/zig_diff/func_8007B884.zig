//! zig_diff spec: func_8007B884 -> func_8007B884.func_8007B884 (146C.c).
//! Inputs: the globals D_800F1860 and D_800F1864 each zero, a sign-bit
//! value, or a plain nonzero value (the edges pick 0, 1, -1 and the i32
//! extremes half the time). The object func_800CB66C returns has its first
//! word (unk0) equal to 1 half the time and otherwise 0, 2, -1 or 0x10001.
//! The C never tests that pointer for null, so the stub always returns a
//! fresh arena block.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B884));

pub const classes = [_][:0]const u8{ "both-zero", "d1860-set", "d1864-set", "both-set" };

/// The unk0 word the stub writes into the object it returns (set by prepare).
var next_unk0: i32 = 1;

pub const stubs = struct {
    pub fn func_800CB66C(ctx: *zd.Ctx) ?*c.D_800F18EC_t {
        const bytes = ctx.allocBytes(64, 16);
        psx.byteAt(i32, bytes, 0).* = next_unk0;
        return @ptrCast(bytes);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]i32{ 0, 1, -1, std.math.minInt(i32), std.math.maxInt(i32) };
    v.g.D_800F1860().* = ctx.pick(i32, &edges);
    v.g.D_800F1864().* = ctx.pick(i32, &edges);
    next_unk0 = if (ctx.chance(2)) 1 else ctx.pick(i32, &.{ 0, 2, -1, 0x10001 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const a = v.g.D_800F1860().* != 0;
    const b = v.g.D_800F1864().* != 0;
    return @as(usize, @intFromBool(b)) * 2 + @as(usize, @intFromBool(a));
}
