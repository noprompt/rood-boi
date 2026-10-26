//! zig_diff spec: func_80074B14 -> func_80074B14.func_80074B14 (146C.c).
//! Inputs: any arg0; func_800A0BE0's result, a spec var the stub returns, drawn
//! from edges so the masked value is zero or nonzero, with and without high
//! bits set. arg1 is always a valid arena object, since both branches read it
//! (the bit-set path reads it as well). func_8008B764 returns an arena block
//! whose byte 18 has bit 0 set or clear. vs_battle_cameraCurrentSpherical.
//! initialDistance is 0x900 half the time. The byte-0 bitfield is random, so
//! the char sign of var_a0 is exercised. The C reads nothing back from the
//! callees after the call except byte 18, which is set before the call.
//! Note: temp_v0 is masked to 0x70000, so its sign bit is never set by
//! construction.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074B14));

pub const classes = [_][:0]const u8{
    "temp-set-bit-clear",
    "temp-set-bit-set-dist-other",
    "temp-set-bit-set-dist-900",
    "temp-clear-bit-clear",
    "temp-clear-bit-set-dist-other",
    "temp-clear-bit-set-dist-900",
};

var callee_ret: c_uint = 0;
var section: ?*c._mpdRoomSection3 = null;
var section_bytes: [*]u8 = undefined;

pub const stubs = struct {
    pub fn func_800A0BE0(ctx: *zd.Ctx, arg0: anytype) c_uint {
        _ = ctx;
        _ = arg0;
        return callee_ret;
    }

    pub fn func_8008B764(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) ?*c._mpdRoomSection3 {
        _ = ctx;
        _ = arg0;
        _ = arg1;
        _ = arg2;
        return section;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg1 = ctx.alloc(v.func_8006EBF8_t_fields);

    const bytes = ctx.allocBytes(32, 16);
    bytes[18] = ctx.edge(u8, &.{ 0x00, 0x01, 0x02, 0x7F, 0x80, 0xFE, 0xFF });
    section_bytes = bytes;
    section = @ptrCast(bytes);

    callee_ret = ctx.pick(c_uint, &.{ 0, 0x10000, 0x20000, 0x40000, 0x70000, 0x80000, 0xFFFF_FFFF, 0x7FFF_FFFF });

    const dist = v.g.vs_battle_cameraCurrentSpherical();
    dist.initialDistance = if (ctx.chance(2)) 0x900 else ctx.int(i32);

    return .{ ctx.int(c_int), arg1 };
}

pub fn classify(args: Args) usize {
    _ = args;
    const temp = (callee_ret & 0x70000) != 0;
    const bit = (section_bytes[18] & 1) != 0;
    const dist900 = v.g.vs_battle_cameraCurrentSpherical().initialDistance == 0x900;
    if (temp) {
        if (!bit) return 0;
        return if (dist900) 2 else 1;
    }
    if (!bit) return 3;
    return if (dist900) 5 else 4;
}
