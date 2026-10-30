//! zig_diff spec: func_8006CDD8 -> func_8006CDD8.func_8006CDD8 (146C.c).
//! Inputs: a random func_8006CE70_t whose unk0 (i32) is often outside the i16
//! range, so the (short) cast wraps (0x18000 becomes negative), and whose unk4
//! (i16) sits at the /128 edges (negatives truncate toward zero). The room
//! lookup returns null about a third of the time and otherwise a random arena
//! room section. func_8008DEAC rewrites that section's unk0/unk2, which the C
//! re-reads for the call to func_800E68EC.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006CDD8));

pub const classes = [_][:0]const u8{ "short-negative", "short-wraps", "in-range" };

pub const stubs = struct {
    pub fn func_8008D438(ctx: *zd.Ctx, x: anytype, y: anytype, z: anytype) [*c]v._mpdRoomSection9 {
        _ = x;
        _ = y;
        _ = z;
        if (ctx.value(u8) < 96) return null;
        return @ptrCast(ctx.alloc(v._mpdRoomSection9));
    }

    pub fn func_8008DEAC(ctx: *zd.Ctx, room: anytype, flag: anytype) void {
        _ = flag;
        const r: *v._mpdRoomSection9 = @ptrCast(@alignCast(room));
        r.unk0 = ctx.value(i16);
        r.unk2 = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_8006CE70_t);
    obj.unk0 = ctx.pick(i32, &.{
        0,      127,     128,      -1,       -127,      -128,
        -129,   0x7FFF,  0x8000,   -0x8000,  -0x8001,   0x18000,
        0x7FFF_FFFF, -0x8000_0000,
    });
    obj.unk4 = ctx.pick(i16, &.{ 0, 127, 128, -127, -128, -129, 32767, -32768 });
    obj.unk6 = ctx.int(i16);
    return .{obj};
}

pub fn classify(args: Args) usize {
    const obj = args[0].?;
    const s: i16 = @truncate(obj.unk0);
    if (s < 0) return 0;
    if (obj.unk0 != @as(i32, s)) return 1;
    return 2;
}
