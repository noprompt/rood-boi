//! zig_diff spec: func_8007CAA4 -> func_8007CAA4.func_8007CAA4 (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors (entry null or an arena actor,
//! its stats pointer null or an arena stats block). The stats' weapon and
//! shield blade ids are 0, 1, 0x8000 or 0xFFFF (or random), so both id tests
//! see zero and nonzero, with and without the sign bit. The
//! func_80077130 stub writes shield.base.id and shield.wepId after the first
//! call, which the C reads back for the shield call. Every branch of the C
//! (null actor, null stats, weapon/shield id zero or not) is reached.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CAA4));

pub const classes = [_][:0]const u8{ "no-actor", "no-stats", "weapon-only", "shield-only", "both", "neither" };

var stats_ptr: *v.vs_battle_actor2 = undefined;

pub const stubs = struct {
    pub fn func_80077130(ctx: *zd.Ctx, actor: anytype, arg: anytype, wep: anytype, slot: anytype, mat: anytype) void {
        _ = actor;
        _ = arg;
        _ = wep;
        _ = slot;
        _ = mat;
        // The real callee can change the shield's ids: the C reads them back
        // for the shield call (after this one).
        if (ctx.value(bool)) stats_ptr.shield.base.id = ctx.value(u16);
        if (ctx.value(bool)) stats_ptr.shield.wepId = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    stats_ptr = stats;
    psx.put(&actor.stats, if (ctx.chance(6)) null else stats);
    stats.weapon.blade.id = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    stats.shield.base.id = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    stats.weapon.wepId = ctx.int(u8);
    stats.weapon.blade.material = ctx.int(u8);
    stats.shield.wepId = ctx.int(u8);
    stats.shield.base.material = ctx.int(u8);

    const idx = ctx.range(u8, 0, 15);
    const table = v.g.vs_battle_actors();
    table[idx] = if (ctx.chance(6)) null else actor;
    return .{@as(c_int, idx)};
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[@as(usize, @intCast(args[0]))] orelse return 0;
    const stats = psx.get(actor.stats) orelse return 1;
    const w = stats.weapon.blade.id != 0;
    const s = stats.shield.base.id != 0;
    if (w and s) return 4;
    if (w) return 2;
    if (s) return 3;
    return 5;
}
