//! zig_diff spec: func_800CB158 -> func_800CB158.func_800CB158 (5BF94.c).
//! Inputs: the loot-list node pointer, either null (one call in four) or a
//! node in the arena. The C stores it without a test, so null is a valid
//! input. Both globals start random and are compared after the call. The
//! menu call is a recording stub that may clear the loot slot itself, so a
//! port that stores after the call, or drops the store, is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB158));

pub const classes = [_][:0]const u8{ "null-node", "node" };

pub const stubs = struct {
    pub fn func_800CACD0(ctx: *zd.Ctx, menuState: anytype, arg1: anytype) c_int {
        _ = menuState;
        _ = arg1;
        // The menu may clear the loot slot the C just set.
        if (ctx.value(u1) == 1) v.g.D_800EB9C8().* = null;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) return .{null};
    const node = ctx.alloc(v.vs_battle_lootListNode);
    return .{node};
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
