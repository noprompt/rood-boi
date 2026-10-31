//! zig_diff spec: func_8007418C -> func_8007418C.func_8007418C (146C.c).
//! Inputs: the global D_800F1910 with a random block; its SVECTOR at offset 8
//! (vx, vy, vz) is the only thing the C reads, and each component is biased
//! toward the edges (0, -1, the i16 extremes) so the sign and the wrap of each
//! (u_short) store are both seen. The C has no branch of its own.
//! _stepTowardTarget receives &sp10, which is a stack address and is not
//! compared, so its stub copies the vector it is given into an arena block
//! (compared as state): a wrong or dropped store in the C changes that block.
//! The stub returns any c_int, which the C returns unchanged.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007418C));

/// The arena block the stub writes the vector it was given into (set by prepare).
var sink: ?*[3]i16 = null;

pub const stubs = struct {
    pub fn _stepTowardTarget(ctx: *zd.Ctx, p: anytype, a: anytype, b: anytype) c_int {
        _ = ctx;
        _ = a;
        _ = b;
        const sv: *const v.SVECTOR = @ptrCast(@alignCast(p));
        sink.?.* = .{ sv.vx, sv.vy, sv.vz };
        return @bitCast(@as(u32, 0x5A5A_1234));
    }
};

pub const classes = [_][:0]const u8{ "vx-negative", "vx-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.D_800F1910();
    g.unk4.unk0.unk4.vx = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    g.unk4.unk0.unk4.vy = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    g.unk4.unk0.unk4.vz = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    sink = ctx.alloc([3]i16);
    sink.?.* = .{ 0, 0, 0 };
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1910().unk4.unk0.unk4.vx < 0) 0 else 1;
}
