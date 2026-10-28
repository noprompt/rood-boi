//! zig_diff spec: func_8008B6EC -> func_8008B6EC.func_8008B6EC (146C.c).
//! Inputs: the room's section3 guest pointer (vs_battle_roomData.section3),
//! set to null, to a 32-bit value with the sign bit set (so the C's unsigned
//! read and the pointer cast see a high address), or to a low address (an
//! arena object's guest address or any value without the sign bit). The
//! function has no branches of its own: the value it returns is the raw
//! guest address, so every input is judged by the pointer it returns.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B6EC));

pub const classes = [_][:0]const u8{ "null", "high-bit", "low" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    // The 4-byte guest address of the section3 pointer, written directly so
    // that null, sign-bit and arena values are all reachable.
    const raw: *align(1) u32 = @ptrCast(&room.section3);
    if (ctx.chance(8)) {
        raw.* = 0;
    } else if (ctx.chance(3)) {
        const obj = ctx.alloc(v._mpdRoomSection3);
        raw.* = @intCast(psx.addr(obj));
    } else if (ctx.chance(2)) {
        raw.* = ctx.int(u32) | 0x8000_0000;
    } else {
        raw.* = ctx.int(u32) & 0x7FFF_FFFF;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const raw = psx.rawOf(v.g.vs_battle_roomData().section3);
    if (raw == 0) return 0;
    if (raw & 0x8000_0000 != 0) return 1;
    return 2;
}
