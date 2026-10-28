//! zig_diff spec: func_8008C49C -> func_8008C49C.func_8008C49C (146C.c).
//! Inputs: vs_battle_roomData.section12 is either null or an 8-element
//! _mpdRoomSection12 array in the arena (arg0 indexes it, 0-7, the length of
//! D_800F1D70). D_800F1D68 is zero or not. arg1 comes from edges (0, the
//! negatives, 63/64/127/128 for the 7-bit field) and any int. The C calls
//! nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C49C));

pub const classes = [_][:0]const u8{ "section-null", "arg1-negative", "flag-set", "arg1-zero", "arg1-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const rooms = v.g.vs_battle_roomData();
    const arr = ctx.alloc([8]v._mpdRoomSection12);
    psx.put(&rooms.section12, if (ctx.chance(5)) null else &arr[0]);
    v.g.D_800F1D68().* = ctx.pick(i16, &.{ 0, 1, -1 });
    const arg0 = ctx.range(c_int, 0, 7);
    const arg1 = ctx.pick(c_int, &.{ 0, 0, 1, -1, 63, 64, 127, 128, -128 });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    if (psx.get(v.g.vs_battle_roomData().section12) == null) return 0;
    const arg1 = args[1];
    if (arg1 < 0) return 1;
    if (v.g.D_800F1D68().* != 0) return 2;
    return if (arg1 == 0) 3 else 4;
}
