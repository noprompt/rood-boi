//! zig_diff spec: func_80085718 -> func_80085718.func_80085718 (146C.c).
//! Inputs: one _hitEntity_t in the arena with every byte random (the header
//! fields, the bitfield word at offset 28, the limbs and the tail). The C
//! zeroes the whole struct with vs_main_bzero, sets unk0.unk3 to 6, and zeroes
//! the four bytes at &inflictStatuses + 1 (the _bits_28 word). The function has
//! no branches, so the value edges are the struct's contents: every byte of the
//! object must match after the call. Some inputs start with unk0.unk3 already 6
//! (the store is then a no-op in the C run) and some with the tail word zero.
//! The bzero stub really zeroes the byte range it is given, so a port that reads
//! the object after the call sees zeros, and the trace records the (pointer,
//! size) arguments.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80085718));

pub const classes = [_][:0]const u8{ "tail-zero", "unk3-already-6", "unk3-other" };

pub const stubs = struct {
    /// vs_main_bzero(p, n): zeroes n bytes at p, as the real callee does.
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const addr: *anyopaque = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
        const bytes: [*]u8 = @ptrCast(addr);
        @memset(bytes[0..@intCast(n)], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // The C dereferences arg0 unconditionally, so it is always a valid object.
    const obj = ctx.alloc(v._hitEntity_t);
    if (ctx.chance(4)) obj.inflictStatuses = 0;
    if (ctx.chance(4)) obj.unk0.unk3 = 6;
    return .{obj};
}

pub fn classify(args: Args) usize {
    const obj = args[0].?;
    if (obj.inflictStatuses == 0) return 0;
    if (obj.unk0.unk3 == 6) return 1;
    return 2;
}
