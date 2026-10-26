//! zig_diff spec: func_8007087C -> func_8007087C.func_8007087C (146C.c).
//! Inputs: a random D_800F19CC_t whose unk4 low byte is the char the C casts,
//! with both signs drawn (0x80 and 0xFF are edges), and random bytes
//! elsewhere. func_800A1108 fills the out-parameter's SVECTOR with random
//! i16 values (pad included, so it is negative about half the time), which
//! the C reads back; rsin and rcos return random ints and the stub records
//! their arguments. The three stores land in unk4C[29].armorDp.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007087C));

pub const classes = [_][:0]const u8{ "char-positive", "char-negative" };

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, a: anytype, out: anytype) c_int {
        _ = a;
        const s: *v.func_8006EBF8_t = @ptrCast(@alignCast(out.?));
        s.unk0.unk4.vx = ctx.value(i16);
        s.unk0.unk4.vy = ctx.value(i16);
        s.unk0.unk4.vz = ctx.value(i16);
        s.unk0.unk4.pad = ctx.value(i16);
        return ctx.value(c_int);
    }
    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return ctx.value(c_int);
    }
    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F19CC_t);
    arg.unk4 = ctx.pick(u32, &.{ 0x7F, 0x80, 0xFF, 0x100, 0xFFFF_FF80 });
    return .{arg};
}

pub fn classify(args: Args) usize {
    return if ((args[0].?.unk4 & 0x80) != 0) 1 else 0;
}
