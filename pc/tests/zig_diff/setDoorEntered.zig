//! zig_diff spec: vs_battle_setDoorEntered -> set_door_entered.setDoorEntered (146C.c).
//! The C has no branches: it stores vs_battle_doorEntered + 1 (an i16 read, computed
//! as int) into the u8 doorEntered field, so the store truncates. Inputs: the global
//! over its whole i16 range with the edges that matter for the +1 and the u8 store
//! (0, 254, 255, 256, -1, 32766, 32767, -32768), plus random values. Classes split
//! negative, small (below 255) and large (255 and up) values.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const psx = @import("common").psx;
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setDoorEntered));

pub const classes = [_][:0]const u8{ "negative", "small", "large" };

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = psx;
    const door = v.g.vs_battle_doorEntered();
    door.* = ctx.pick(i16, &.{ 0, 1, 254, 255, 256, -1, 32766, 32767, -32768 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const door = v.g.vs_battle_doorEntered().*;
    if (door < 0) return 0;
    if (door < 255) return 1;
    return 2;
}
