//! zig_diff spec: vs_battle_getMenuItem -> get_menu_item.getMenuItem (5BF94.c).
//! Inputs: the global menu-item pointer set to an arena array of 16 items at a
//! random slot, and an id that is zero, negative, small or large (up to about
//! 10^5 in magnitude, so the 36-byte scaling never leaves 64-bit range). The
//! C has no branches and no comparisons; the result is pure pointer arithmetic,
//! so the value edges are the sign of id and its zero/small/large range.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getMenuItem));

pub const classes = [_][:0]const u8{ "id-zero", "id-negative", "id-small", "id-large" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const items: [*]v.vs_battle_menuItem_t = @ptrCast(@alignCast(
        ctx.allocBytes(@sizeOf(v.vs_battle_menuItem_t) * 16, 16),
    ));
    // The table pointer: a valid arena slot, never null (the C does no test).
    v.g.vs_battle_menuItems().* = &items[ctx.range(usize, 0, 15)];

    const id: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 0, 1, -1, 2, 15, 16, -16, 255, 256, -255, -256 })
    else
        ctx.range(c_int, -100000, 100000);
    return .{id};
}

pub fn classify(args: Args) usize {
    const id = args[0];
    if (id == 0) return 0;
    if (id < 0) return 1;
    if (id < 256) return 2;
    return 3;
}
