//! zig_diff spec: func_800CB18C -> func_800CB18C.func_800CB18C (5BF94.c).
//! Inputs: the loot pointer is null, an arena object, or a stray scratchpad
//! address. The C only stores it and never reads it, so every value is valid.
//! The callee func_800CACD0 is a recording stub that returns any int and
//! sometimes clears D_800EB9C8, so the C's store must happen before the call
//! and its final value must survive the call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB18C));

pub const classes = [_][:0]const u8{ "null-loot", "arena-loot", "stray-loot" };

pub const stubs = struct {
    pub fn func_800CACD0(ctx: *zd.Ctx, menuState: anytype, arg1: anytype) c_int {
        _ = menuState;
        _ = arg1;
        // The callee may rewrite the global the C just stored: the C's final
        // state must match the port's whether or not this happens.
        if (ctx.value(u1) == 1) v.g.D_800EB9C8().* = null;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const loot: ?*v.vs_battle_loot = switch (ctx.range(u8, 0, 2)) {
        0 => null,
        1 => ctx.alloc(v.vs_battle_loot),
        else => @ptrFromInt(zd.scratchpad + 0x100),
    };
    return .{loot};
}

pub fn classify(args: Args) usize {
    const p = args[0] orelse return 0;
    if (@intFromPtr(p) == zd.scratchpad + 0x100) return 2;
    return 1;
}
