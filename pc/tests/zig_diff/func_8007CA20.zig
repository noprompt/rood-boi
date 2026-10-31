//! zig_diff spec: func_8007CA20 -> func_8007CA20.func_8007CA20 (146C.c).
//! Inputs: an actor index 0-14 over the 16-entry vs_battle_actors table, so
//! the entry at index+1 is also in the table and both entries are set by
//! prepare: the actor's entry is NULL or a fresh arena actor, and the next
//! entry is NULL or a different fresh actor. Blade/shield weapon ids come
//! over edge values (the callee ignores them, so the trace compares them as
//! passed). The func_80077130 stub may overwrite the actor's
//! equippedWeaponCategory, as the real callee can, and the C's null test sees
//! both outcomes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CA20));

pub const classes = [_][:0]const u8{ "no-actor", "actor" };

pub const stubs = struct {
    pub fn func_80077130(ctx: *zd.Ctx, p: anytype, id: anytype, wep: anytype, hand: anytype, flag: anytype) void {
        _ = id;
        _ = wep;
        _ = hand;
        _ = flag;
        if (p != null) {
            const a: *v.vs_battle_actor = @ptrCast(@alignCast(p.?));
            if (ctx.value(u1) == 1) a.equippedWeaponCategory = ctx.value(u8);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const id = ctx.range(c_int, 0, 14);
    const table = v.g.vs_battle_actors();
    const actor: ?*v.vs_battle_actor = if (ctx.chance(3)) null else ctx.alloc(v.vs_battle_actor);
    const next: ?*v.vs_battle_actor = if (ctx.chance(2)) null else ctx.alloc(v.vs_battle_actor);
    table[@intCast(id)] = actor;
    table[@intCast(id + 1)] = next;
    const blade = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fff_ffff, -0x8000_0000 });
    const shield = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fff_ffff, -0x8000_0000 });
    return .{ id, blade, shield };
}

pub fn classify(args: Args) usize {
    return if (v.g.vs_battle_actors()[@intCast(args[0])] == null) 0 else 1;
}
