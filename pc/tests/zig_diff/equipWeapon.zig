//! zig_diff spec: vs_battle_equipWeapon -> equip_weapon.equipWeapon (146C.c).
//! Inputs: the battle's character state (an arena actor whose stats block is
//! an arena vs_battle_actor2), and a weapon that is null, has blade 0 (the
//! C's signed index -1 into blades), or has blade 1-16. The stats' weapon
//! range and reach are rewritten by the applyWeapon and nop0 stubs, as the
//! real callees may, so the C's read-backs after those calls are compared.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").equipWeapon));

pub const classes = [_][:0]const u8{ "no-weapon", "blade-0", "blade-1-16" };

var stats: *v.vs_battle_actor2 = undefined;

pub const stubs = struct {
    pub fn vs_battle_applyWeapon(ctx: *zd.Ctx, weapon: anytype, src: anytype) void {
        _ = weapon;
        _ = src;
        if (ctx.value(u1) == 1) stats.weapon.range.range = ctx.value(u8);
        if (ctx.value(u1) == 1) stats.weapon.range.unk1 = ctx.value(u8);
        if (ctx.value(u1) == 1) stats.weapon.range.unk2 = ctx.value(u8);
        if (ctx.value(u1) == 1) psx.setBits(&stats.weapon.range, "attackShapeAngle", ctx.value(u5));
        if (ctx.value(u1) == 1) psx.setBits(stats, "reach", ctx.value(u5));
    }

    pub fn vs_battle_nop0(ctx: *zd.Ctx, p: anytype) void {
        _ = p;
        if (ctx.value(u1) == 1) psx.setBits(stats, "reach", ctx.value(u5));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    v.g.vs_battle_characterState().* = actor;
    if (ctx.chance(4)) return .{null};
    const weapon = ctx.alloc(v.vs_main_inventoryWeapon);
    weapon.blade = if (ctx.chance(2))
        ctx.edge(u8, &.{ 0, 1, 2, 8, 15, 16 })
    else
        ctx.range(u8, 0, 16);
    return .{weapon};
}

pub fn classify(args: Args) usize {
    const w = args[0] orelse return 0;
    return if (w.blade == 0) 1 else 2;
}
