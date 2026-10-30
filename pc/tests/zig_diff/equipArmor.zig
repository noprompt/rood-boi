//! zig_diff spec: vs_battle_equipArmor -> equip_armor.equipArmor (146C.c).
//! Inputs: a characterState actor whose stats block sits in the middle of a
//! three-block arena allocation, so limbs[bodyPart] reads and writes stay inside
//! memory the harness owns for bodyPart -1, 6 and 7 as well as 0-5; the armor
//! argument is null or a random arena object. The C has no branches of its own.
//! applyArmor and nop0 are recording stubs that write the fields the real
//! callees can change; the two no-argument calls stay recording stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").equipArmor));

pub const classes = [_][:0]const u8{ "null-armor", "armor-body-part-0-5", "armor-body-part-out-of-range" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    // Three stats blocks: one before and one after the block the stats pointer
    // names, so the out-of-range limb indices still address the arena.
    const block = ctx.allocBytes(3 * @sizeOf(v.vs_battle_actor2), 16);
    const stats: *v.vs_battle_actor2 = @ptrCast(@alignCast(block + @sizeOf(v.vs_battle_actor2)));
    psx.put(&actor.stats, stats);
    v.g.vs_battle_characterState().* = actor;

    const armor: ?*v.vs_main_inventoryArmor = if (ctx.chance(6)) null else ctx.alloc(v.vs_main_inventoryArmor);
    const bodyPart: c_int = if (ctx.chance(3))
        ctx.edge(c_int, &.{ -1, 6, 7 })
    else
        ctx.range(c_int, 0, 5);
    return .{ bodyPart, armor };
}

pub fn classify(args: Args) usize {
    if (args[1] == null) return 0;
    if (args[0] < 0 or args[0] > 5) return 2;
    return 1;
}

pub const stubs = struct {
    pub fn vs_battle_applyArmor(ctx: *zd.Ctx, dst: anytype, armor: anytype) void {
        _ = armor;
        const p: ?*anyopaque = dst;
        const a: *v.vs_battle_uiArmor = @ptrCast(@alignCast(p.?));
        a.currentDp = ctx.value(u16);
        a.currentStr = ctx.value(i16);
    }

    pub fn vs_battle_nop0(ctx: *zd.Ctx, p: anytype) void {
        const q: ?*anyopaque = p;
        const s: *v.vs_battle_actor2 = @ptrCast(@alignCast(q.?));
        s.currentHP = ctx.value(i16);
    }
};
