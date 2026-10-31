//! zig_diff spec: func_800D1EF0 -> func_800D1EF0.func_800D1EF0 (5BF94.c).
//! Inputs: arg0 is the mask of table entries to fill, with its low nibble
//! classed as none, all or some set bits, and sign-bit and high-bit masks
//! included; arg1..arg6 are each drawn from edge values (0, +-1, 255, 256,
//! INT_MIN, INT_MAX) or random, so every bitfield store sees truncation and
//! wrap. The callees are recording stubs that write back into the entry
//! they are passed and into the table, as the real ones may, and return
//! any u8.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1EF0));

pub const classes = [_][:0]const u8{ "mask-low-nibble-zero", "mask-low-nibble-all", "mask-low-nibble-some" };

fn edgeInt(ctx: *zd.Ctx) c_int {
    return ctx.pick(c_int, &.{ 0, 1, -1, 2, 255, 256, 0x7FFF_FFFF, std.math.minInt(c_int) });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.pick(c_int, &.{ 0, 1, 0x0F, 0x10, 0xF0, -1, 0x0A, 0x7FFF_FFFF, std.math.minInt(c_int) });
    return .{ arg0, edgeInt(ctx), edgeInt(ctx), edgeInt(ctx), edgeInt(ctx), edgeInt(ctx), edgeInt(ctx) };
}

pub fn classify(args: Args) usize {
    const low = args[0] & 0xF;
    if (low == 0) return 0;
    if (low == 0xF) return 1;
    return 2;
}

pub const stubs = struct {
    // The real callee may rewrite the entry it is given, and its result is
    // stored into unk5 after the call.
    pub fn func_800D1E78(ctx: *zd.Ctx, p: anytype) u8 {
        const e: *v.D_800F54B8_t = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) e.unk2 = ctx.value(u8);
        if (ctx.value(u1) == 1) psx.setBits(e, "unk1_0", ctx.value(u5));
        return ctx.value(u8);
    }

    // The real callee may rewrite any table entry.
    pub fn func_800D1DE4(ctx: *zd.Ctx, arg0: c_int) void {
        _ = arg0;
        if (ctx.value(u1) == 1) {
            const arr = v.g.D_800F54B8();
            arr[ctx.value(u8) & 3].unk4 = ctx.value(u8);
            if (ctx.value(u1) == 1) arr[ctx.value(u8) & 3].unk0 = ctx.value(u8);
        }
    }
};
