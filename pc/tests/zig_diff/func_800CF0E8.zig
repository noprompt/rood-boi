//! zig_diff spec: func_800CF0E8 -> func_800CF0E8.func_800CF0E8 (5BF94.c).
//! Inputs: a random func_800CF0E8_t in the arena, with unk4 equal to 4 half the
//! time so the copy-arguments branch runs. arg1 is zero, positive or negative
//! (the edges include -1, INT_MIN and INT_MAX), and arg2 sits around the u8
//! narrowing edges. Callees: func_800CF49C returns any int, which the C narrows
//! into the u8 global D_800F5318. func_800CF478 rewrites D_800F5318, which the C
//! reads back as its return value. The two func_800D1B18 calls write the object
//! they are passed.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF0E8));

pub const classes = [_][:0]const u8{ "arg1-zero", "unk4-not-4", "copy-positive", "copy-negative" };

pub const stubs = struct {
    pub fn func_800CF49C(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }

    pub fn func_800D7890(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        v.g.D_800F522C().* = ctx.value(u8);
    }

    pub fn func_800D1B18(ctx: *zd.Ctx, p: anytype) void {
        const o: *v.D_800F54D8_t = @ptrCast(@alignCast(p));
        o.roll = ctx.value(i32);
    }

    pub fn func_800CF478(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        v.g.D_800F5318().* = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_800CF0E8_t);
    obj.unk4 = if (ctx.chance(2)) 4 else ctx.pick(u16, &.{ 0, 3, 5, 0xFFFF });
    const arg1: c_int = if (ctx.chance(5)) 0 else ctx.pick(c_int, &.{ 1, -1, 255, 256, std.math.maxInt(c_int), std.math.minInt(c_int) });
    const arg2: c_int = ctx.pick(c_int, &.{ 0, 1, 255, 256, -1 });
    return .{ obj, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    if (args[1] == 0) return 0;
    if (args[0].?.unk4 != 4) return 1;
    return if (args[1] < 0) 3 else 2;
}
