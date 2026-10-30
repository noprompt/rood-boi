//! zig_diff spec: func_8007D260 -> func_8007D260.func_8007D260 (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors (16 entries). Each entry is
//! null or an arena actor whose unk8 is 0, 0x20, 0x21 or 0xFF. The callee
//! func_8009DC38 (called with the index) may rewrite that actor's unk8 and
//! returns nothing, so the C's later state is checked as well.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D260));

pub const classes = [_][:0]const u8{ "null-actor", "unk8-0x20", "unk8-other" };

pub const stubs = struct {
    pub fn func_8009DC38(ctx: *zd.Ctx, arg: anytype) void {
        if (ctx.value(u1) == 0) return;
        const table = v.g.vs_battle_actors();
        const i: usize = @intCast(arg);
        const actor = table[i] orelse return;
        actor.unk8 = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        if (ctx.chance(4)) {
            table[i] = null;
        } else {
            const actor = ctx.alloc(v.vs_battle_actor);
            actor.unk8 = ctx.pick(u8, &.{ 0, 0x20, 0x21, 0xFF });
            table[i] = actor;
        }
    }
    return .{ctx.range(c_int, 0, 15)};
}

pub fn classify(args: Args) usize {
    const table = v.g.vs_battle_actors();
    const i: usize = @intCast(args[0]);
    const actor = table[i] orelse return 0;
    return if (actor.unk8 == 0x20) 1 else 2;
}
