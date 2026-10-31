//! zig_diff spec: func_8008E470 -> func_8008E470.func_8008E470 (146C.c).
//! Inputs: the raw guest address of vs_battle_roomData.section14, which is
//! the only thing the function reads. The edges are 0, 1, 2 and the values
//! where an unsigned compare and a signed one part ways (0x80000000,
//! 0xFFFFFFFF). The rest is random, so the 1-boundary and the high bit both
//! come up often.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E470));

pub const classes = [_][:0]const u8{ "raw-zero", "raw-one", "raw-high-bit", "raw-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const raw = ctx.pick(u32, &.{ 0, 1, 2, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
    // Write the 4 guest-address bytes directly: no pointer is made from raw,
    // so odd values are fine.
    std.mem.writeInt(u32, std.mem.asBytes(&room.section14), raw, .little);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const raw = psx.rawOf(v.g.vs_battle_roomData().section14);
    return switch (raw) {
        0 => 0,
        1 => 1,
        0x8000_0000...0xFFFF_FFFF => 2,
        else => 3,
    };
}
