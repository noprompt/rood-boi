//! zig_diff spec: vs_battle_equipAccessory -> equip_accessory.equipAccessory (146C.c).
//! Inputs: the accessory argument (null or an arena object) and the global
//! vs_battle_characterState pointing at either of two arena actors, each with
//! its own valid stats block. The C reads the global twice, so applyAccessory's
//! stub sometimes redirects it to the other actor, and nop0 must receive the
//! new stats pointer. applyAccessory and nop0 are recording stubs that write
//! the fields the real callees write; the two func_ calls are void recorders.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").equipAccessory));

pub const classes = [_][:0]const u8{ "null-accessory", "global-main", "global-other" };

/// The second actor the global may be redirected to (set by prepare).
var other_actor: ?*v.vs_battle_actor = null;

/// Views a pointer argument (optional or not) as `*T`.
fn asPtr(comptime T: type, p: anytype) *T {
    const q = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
    return @ptrCast(@alignCast(q));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const main = ctx.alloc(v.vs_battle_actor);
    const other = ctx.alloc(v.vs_battle_actor);
    psx.put(&main.stats, ctx.alloc(v.vs_battle_actor2));
    psx.put(&other.stats, ctx.alloc(v.vs_battle_actor2));
    other_actor = other;
    // The C reads this global without a null test, so it is always valid.
    v.g.vs_battle_characterState().* = if (ctx.chance(3)) other else main;
    if (ctx.chance(8)) return .{null};
    return .{ctx.alloc(v.vs_main_inventoryArmor)};
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (v.g.vs_battle_characterState().* == other_actor) return 2;
    return 1;
}

pub const stubs = struct {
    pub fn vs_battle_applyAccessory(ctx: *zd.Ctx, accessory: anytype, armor: anytype) void {
        _ = armor;
        const ui = asPtr(v.vs_battle_uiAccessory, accessory);
        ui.currentStr = ctx.value(i16);
        ui.dropRate = ctx.value(u8);
        // The C reads characterState again for nop0: the callee may redirect it.
        if (ctx.value(u8) < 64) v.g.vs_battle_characterState().* = other_actor;
    }

    pub fn vs_battle_nop0(ctx: *zd.Ctx, stats: anytype) void {
        const s = asPtr(v.vs_battle_actor2, stats);
        s.currentHP = ctx.value(i16);
        s.maxHP = ctx.value(i16);
    }
};
