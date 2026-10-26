//! zig_diff spec: func_80076F24 -> func_80076F24.func_80076F24 (146C.c).
//! Inputs: an id 0-15 (slots 0 and 1, then the default switch), a
//! charInitData in the arena, all 16 vs_battle_actors entries pointing at
//! arena actors (each with the shared stats block or null), and random
//! arg2-arg5 with the sign bit of arg4 random (its low two bits pick the
//! default arm). The stubs write the actor the C passes through:
//! func_8009D934 sets weaponDrawn (the C ORs it before the call) and
//! func_80076784 sets unk1E. The inner switch's implicit no-match edge is
//! unreachable: arg4 & 3 is always 0-3 and cases 0-3 cover all of them.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80076F24));

pub const classes = [_][:0]const u8{ "id0", "id1", "default-arm1", "default-arm2-3", "default-arm0" };

pub const stubs = struct {
    pub fn func_8009D934(ctx: *zd.Ctx, id: anytype, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        const actor = v.g.vs_battle_actors()[@intCast(id)].?;
        actor.weaponDrawn = ctx.value(i32);
    }

    pub fn func_80076784(ctx: *zd.Ctx, id: anytype, actor2: anytype, init: anytype, arg3: anytype) void {
        _ = actor2;
        _ = init;
        _ = arg3;
        const actor = v.g.vs_battle_actors()[@intCast(id)].?;
        actor.unk1E = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    const stats = ctx.alloc(v.vs_battle_actor2);
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        psx.put(&actor.stats, if (ctx.chance(8)) null else stats);
        table[i] = actor;
    }

    const init = ctx.alloc(v.vs_battle_charInitData);
    const id = ctx.range(c_int, 0, 15);
    const arg2 = ctx.pick(c_int, &.{ 0, -1, 255, 256, 0x7fffffff, -2147483648 });
    const arg3 = ctx.pick(c_int, &.{ 0, -1, 255, 256, 0x7fffffff, -2147483648 });
    const arg4 = ctx.int(c_int);
    const arg5 = ctx.pick(c_int, &.{ 0, -1, 1, 0x7fffffff, -2147483648 });
    return .{ id, init, arg2, arg3, arg4, arg5 };
}

pub fn classify(args: Args) usize {
    const id = args[0];
    if (id == 0) return 0;
    if (id == 1) return 1;
    return switch (args[4] & 3) {
        1 => 2,
        2, 3 => 3,
        else => 4,
    };
}
