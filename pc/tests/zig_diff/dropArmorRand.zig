//! zig_diff spec: _dropArmorRand -> drop_armor_rand.dropArmorRand (146C.c).
//! Inputs: a uiArmor whose drop rate is an edge (0, 1, 127, 128, 255) or any
//! byte, and a two-slot looted array whose slots are free (id 0, a third of
//! the time) or taken (id 1, 0x80, 0xFF). The roll vs_main_getRand returns is
//! chosen around the rate: equal to it (the `<` edge), one below, one above,
//! -1 (signed compare), 255, or any byte. The copy is a recording stub that
//! writes the destination's id and maxDp. Classes: no drop, drop into slot 0,
//! drop into slot 1, drop with both slots taken.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropArmorRand));

pub const classes = [_][:0]const u8{ "no-drop", "drop-slot0", "drop-slot1", "no-free-slot" };

/// The roll the stub returns this iteration (set by prepare).
var rand_ret: c_int = 0;
var slots: *[2]v.vs_battle_lootedArmor = undefined;
var rate_base: *v.vs_battle_uiArmor = undefined;

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = ctx;
        _ = arg;
        return rand_ret;
    }

    pub fn vs_battle_copyUiEquipmentStats(ctx: *zd.Ctx, dst: anytype, equipment: anytype) void {
        _ = equipment;
        const d: *v.vs_main_inventoryArmor = @ptrCast(@alignCast(dst));
        d.id = ctx.value(u8);
        d.maxDp = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arr = ctx.alloc([2]v.vs_battle_lootedArmor);
    const base = ctx.alloc(v.vs_battle_uiArmor);
    slots = arr;
    rate_base = base;

    base.dropRate = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    const d: c_int = base.dropRate;
    rand_ret = switch (ctx.range(u8, 0, 9)) {
        0...3 => d,
        4 => d - 1,
        5 => d + 1,
        6 => -1,
        7 => 255,
        else => @as(c_int, ctx.int(u8)),
    };

    for (arr) |*s| {
        s.armor.id = if (ctx.chance(3)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
    }
    return .{ &arr[0], base };
}

pub fn classify(args: Args) usize {
    _ = args;
    if (rand_ret >= @as(c_int, rate_base.dropRate)) return 0;
    if (slots[0].armor.id == 0) return 1;
    if (slots[1].armor.id == 0) return 2;
    return 3;
}
