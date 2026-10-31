//! zig_diff spec: func_800CB114 -> func_800CB114.func_800CB114 (5BF94.c).
//! Inputs: the global vs_battle_menuItems is either null or a pointer to an
//! arena block (which the free stub never reads). The one callee,
//! func_8007E1C0, can change the global the C reads back after the call
//! (cleared, or replaced by another arena block), and returns any c_int,
//! which the C ignores. The free stub records its argument, so a port that
//! frees a value cached before the call is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB114));

pub const classes = [_][:0]const u8{ "menu-items-null", "menu-items-live" };

pub const stubs = struct {
    pub fn func_8007E1C0(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        // The callee may clear the global or replace it before the C reads it back.
        const roll = ctx.value(u8);
        if (roll < 96) {
            v.g.vs_battle_menuItems().* = null;
        } else if (roll < 160) {
            v.g.vs_battle_menuItems().* = ctx.alloc(v.vs_battle_menuItem_t);
        }
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.vs_battle_menuItems();
    g.* = if (ctx.chance(3)) null else ctx.alloc(v.vs_battle_menuItem_t);
    return .{};
}

pub fn classify(_: Args) usize {
    return if (v.g.vs_battle_menuItems().* == null) 0 else 1;
}
