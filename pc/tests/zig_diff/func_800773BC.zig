//! zig_diff spec: func_800773BC -> func_800773BC.func_800773BC (146C.c).
//! Inputs: an arena actor whose allegiance (its low three bits are the C's
//! `unk1C & 7` test) and weaponDrawn (`& 1`, with the sign bit set or clear)
//! come from edge-heavy pools, a slot index 0-15 (slot 0 is the `arg1 != 0`
//! split), vs_battle_actors[0] set to a valid actor (the arena actor itself
//! sometimes, so the copy and set alias), and random extra arguments. The
//! callees that touch the actor (func_80076D50 and func_800E6178) write it
//! back through stubs, so the port must re-read fields after each call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800773BC));

pub const classes = [_][:0]const u8{ "bits-clear", "copy-idx0", "copy-other-holstered", "copy-other-drawn" };

pub const stubs = struct {
    /// Changes the actor in slot `a1` (the C stored arg0 there before the call):
    /// allegiance and weaponDrawn, which the C tests after the call.
    pub fn func_80076D50(ctx: *zd.Ctx, a1: anytype, a2: anytype, a3: anytype, a4: anytype, a5: anytype) void {
        _ = a2;
        _ = a3;
        _ = a4;
        _ = a5;
        const tbl = v.g.vs_battle_actors();
        const idx: usize = @intCast(a1);
        if (ctx.value(u1) == 1) {
            if (tbl[idx]) |a| a.allegiance = ctx.value(u16);
        }
        if (ctx.value(u1) == 1) {
            if (tbl[idx]) |a| a.weaponDrawn = ctx.value(i32);
        }
    }

    /// Initialises the actor (writes unk34 sometimes) and returns any int.
    pub fn func_800E6178(ctx: *zd.Ctx, p: anytype, n: anytype) c_int {
        _ = n;
        const a: *v.vs_battle_actor = @ptrCast(@alignCast(p.?));
        if (ctx.value(u1) == 1) a.unk34 = ctx.value(i32);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const other = ctx.alloc(v.vs_battle_actor);
    const tbl = v.g.vs_battle_actors();
    // Slot 0 must be a valid actor: the C copies vs_battle_actors[0]->next
    // when arg1 != 0. Sometimes it is the arg0 actor itself (aliasing).
    tbl[0] = if (ctx.chance(4)) actor else other;

    actor.allegiance = ctx.pick(u16, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 0x8000, 0xFFFF });
    actor.weaponDrawn = ctx.pick(i32, &.{ 0, 1, 2, 3, -1, -2, -2147483648, 0x7FFF_FFFF });
    const idx = ctx.range(c_int, 0, 15);

    return .{ actor, idx, ctx.int(c_int), ctx.int(c_int), ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    if ((a.allegiance & 7) == 0) return 0;
    if (args[1] == 0) return 1;
    return if ((a.weaponDrawn & 1) != 0) 3 else 2;
}
