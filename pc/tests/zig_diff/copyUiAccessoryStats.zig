//! zig_diff spec: vs_battle_copyUiAccessoryStats -> copy_ui_accessory_stats.copyUiAccessoryStats (146C.c).
//! Inputs: a valid arena target and a uiAccessory whose accessory.id is 0, 1,
//! 2, 0x8000, 0xFFFF or random, so the test sees zero, nonzero values with and
//! without the sign bit, and the id == 1 case a `>= 2` bound gets wrong. The
//! other accessory fields are random, so a wrong field shows. The callee is a
//! recording stub that writes the target it is given, so a port that reads the
//! target back or skips the call differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").copyUiAccessoryStats));

pub const classes = [_][:0]const u8{ "id-zero", "id-high-bit", "id-low-nonzero" };

fn asArmor(p: anytype) *v.vs_main_inventoryArmor {
    const P = @TypeOf(p);
    const q = if (@typeInfo(P) == .optional) p.? else p;
    return @ptrCast(@alignCast(q));
}

pub const stubs = struct {
    pub fn vs_battle_copyUiEquipmentStats(ctx: *zd.Ctx, target: anytype, equipment: anytype) void {
        _ = equipment;
        const t = asArmor(target);
        t.id = ctx.value(u8);
        t.maxDp = ctx.value(u16);
        t.material = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_main_inventoryArmor);
    const source = ctx.alloc(v.vs_battle_uiAccessory);
    source.accessory.id = ctx.pick(u16, &.{ 0, 1, 2, 0x8000, 0xFFFF });
    source.accessory.subId = ctx.pick(i8, &.{ 0, 1, -1 });
    source.accessory.index = ctx.pick(u8, &.{ 0, 1 });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1].?;
    const id = source.accessory.id;
    if (id == 0) return 0;
    if (id & 0x8000 != 0) return 1;
    return 2;
}
