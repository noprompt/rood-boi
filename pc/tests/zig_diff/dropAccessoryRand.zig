//! zig_diff spec: _dropAccessoryRand -> drop_accessory_rand.dropAccessoryRand (146C.c).
//! Inputs: a looted slot and a UI accessory in the arena. The roll the stubbed
//! vs_main_getRand returns is an edge value (negative, 0, 1, 127, 128, 254,
//! 255, 256). The drop rate is the roll truncated to u8 half the time, so the
//! `<` test sees equal sides often, and otherwise a u8 edge (0, 1, 127, 128,
//! 255), where a signed read of dropRate differs. The copy stub writes the
//! looted accessory, and the state hash at that call sees whatever the port
//! stored before it.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropAccessoryRand));

pub const classes = [_][:0]const u8{ "hit", "miss-equal", "miss-above" };

/// The roll the stubbed vs_main_getRand returns in this iteration (set by prepare).
var roll: c_int = 0;

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = ctx;
        _ = n;
        return roll;
    }

    pub fn vs_battle_copyUiEquipmentStats(ctx: *zd.Ctx, dst: anytype, src: anytype) void {
        _ = src;
        const d: *v.vs_main_inventoryArmor = @ptrCast(@alignCast(dst));
        d.maxDp = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const looted = ctx.alloc(v.vs_battle_lootedAccessory);
    const base = ctx.alloc(v.vs_battle_uiAccessory);
    roll = ctx.pick(c_int, &.{ -1, 0, 1, 127, 128, 254, 255, 256 });
    base.dropRate = if (ctx.chance(2))
        @as(u8, @truncate(@as(u32, @bitCast(roll))))
    else
        ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    return .{ looted, base };
}

pub fn classify(args: Args) usize {
    const rate: c_int = args[1].?.dropRate;
    if (roll < rate) return 0;
    if (roll == rate) return 1;
    return 2;
}
