//! zig_diff spec: func_800741D4 -> func_800741D4.func_800741D4 (146C.c).
//! Inputs: the mode word D_800F196C (8 about half the time, otherwise
//! 0, 1, 7, 9, 0x80000008 and -1, so both sides of the test and near
//! misses are hit), and the D_800F1910 block whose room-section pointer is
//! either null or an arena object. The unkC word and the camera and tick
//! globals keep their random fill. The two callees are recording stubs that
//! write the camera mode, the tick speed and the passed block's unkC, so a
//! port that reads those back, moves a store across a call, or passes the
//! wrong argument differs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800741D4));

pub const classes = [_][:0]const u8{ "not-8-null", "not-8-ptr", "8-null", "8-ptr" };

pub const stubs = struct {
    pub fn func_80073D30(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = c;
        v.g._cameraMode().* = ctx.value(u32);
        if (b) |p| {
            const blk: *v.func_8006EBF8_t = @ptrCast(@alignCast(p));
            blk.unkC = ctx.value(i32);
        }
    }

    pub fn func_80073E30(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        v.g.vs_gametime_tickspeed().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_800F1910();
    const obj = ctx.alloc(v._mpdRoomSectionA);
    psx.put(&d.unk0, if (ctx.chance(2)) null else obj);
    v.g.D_800F196C().* = if (ctx.chance(2))
        8
    else
        ctx.pick(u32, &.{ 0, 1, 7, 9, 0x8000_0008, 0xFFFF_FFFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F1910();
    const is8 = v.g.D_800F196C().* == 8;
    const isNull = psx.get(d.unk0) == null;
    if (is8) return if (isNull) 2 else 3;
    return if (isNull) 0 else 1;
}
