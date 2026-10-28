//! zig_diff spec: func_80088CAC -> func_80088CAC.func_80088CAC (146C.c).
//! Inputs: D_80050468.unk2 equal to 2 (half the runs, so the guard is taken
//! and not taken), plus the values a porter could misread: 0, 1, 3, 0x102 and
//! 0x202 (low byte 2, high byte set), and 0xFFFF. Both callees are recording
//! stubs. func_8007BCCC and func_80069DBC may rewrite D_80050468 (unk0 and
//! unk2), so the C's read of unk2 after each call is exercised, and a port
//! that reads it at the wrong time or from the wrong width differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80088CAC));

pub const classes = [_][:0]const u8{ "unk2-not-two", "unk2-two" };

pub const stubs = struct {
    pub fn func_8007BCCC(ctx: *zd.Ctx) void {
        const d = v.g.D_80050468();
        if (ctx.value(u1) == 1) d.unk0 = ctx.value(u8);
        if (ctx.value(u1) == 1) d.unk2 = ctx.value(u16);
    }

    pub fn func_80069DBC(ctx: *zd.Ctx) void {
        const d = v.g.D_80050468();
        if (ctx.value(u1) == 1) d.unk2 = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_80050468();
    d.unk2 = if (ctx.chance(2)) 2 else ctx.pick(u16, &.{ 0, 1, 3, 0x102, 0x202, 0xFFFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_80050468().unk2 == 2) 1 else 0;
}
