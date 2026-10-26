//! zig_diff spec: vs_battle_copyUiWeaponStats -> copy_ui_weapon_stats.copyUiWeaponStats (146C.c).
//! Inputs: a weapon with a random target (blade, grip and gem indices from
//! 0, which the C turns into index -1, through 16, past the arrays) and a
//! source whose blade and gem ids are zero or edges around the sign bit
//! (0x7FFF, 0x8000, 0xFFFF). The blade and grip stubs write the state the C
//! reads back: the target's gem indices and the source's gem ids. The target is
//! null one run in six, always with an empty blade (the C never reads it then).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiWeaponStats));

pub const classes = [_][:0]const u8{ "no-blade", "blade-no-gems", "blade-with-gem" };

var target_obj: ?*v.vs_main_inventoryWeapon = null;
var source_obj: ?*v.vs_battle_uiWeapon = null;

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryWeapon);
    // The C reads the target only after the blade test: a null target with an empty blade must pass.
    const null_target = ctx.chance(6);
    const source = ctx.alloc(v.vs_battle_uiWeapon);
    target_obj = target;
    source_obj = source;

    const ids = [_]u16{ 0, 1, 0x7FFF, 0x8000, 0xFFFF };
    const indices = [_]u8{ 0, 1, 2, 4, 9, 16 };

    target.blade = ctx.pick(u8, &indices);
    target.grip = ctx.pick(u8, &indices);
    for (&target.gems) |*g| g.* = ctx.pick(u8, &indices);

    source.blade.id = if (ctx.chance(5)) 0 else ctx.pick(u16, &ids);
    source.currentDp = ctx.int(u16);
    source.currentPp = ctx.int(u16);
    for (&source.gems) |*gem| gem.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &ids);

    if (null_target) source.blade.id = 0;
    return .{ if (null_target) null else target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    if (source.blade.id == 0) return 0;
    for (source.gems) |gem| {
        if (gem.id != 0) return 2;
    }
    return 1;
}

pub const stubs = struct {
    // The blade copy writes the target's gem indices, which the C reads back
    // for each gem it copies.
    pub fn vs_battle_copyUiBladeStats(ctx: *zd.Ctx, dropBlade: anytype, targetBlade: anytype) void {
        _ = dropBlade;
        _ = targetBlade;
        target_obj.?.gems[ctx.value(u8) % 4] = ctx.value(u8);
    }

    // The grip copy writes a gem id of the source, which the C's gem loop
    // reads back after this call.
    pub fn vs_battle_copyUiGripStats(ctx: *zd.Ctx, dropGrip: anytype, targetGrip: anytype) void {
        _ = dropGrip;
        _ = targetGrip;
        source_obj.?.gems[ctx.value(u8) % 3].id = ctx.value(u16);
    }
};
