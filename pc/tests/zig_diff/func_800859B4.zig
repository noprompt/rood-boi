//! zig_diff spec: func_800859B4 -> func_800859B4.func_800859B4 (146C.c).
//! Inputs: arg2 across zero, both signs (-1, minInt, 1, maxInt, 0). arg0 at
//! the unsigned bound 0x16..0x36 (0x36 makes the bound compare's sides equal),
//! plus indices 0..255 (the only ones the C may read, since it reads
//! vs_main_actions[arg0].flags_0 only past the bound check). A null arg1 when
//! arg2 is 0, where the C never dereferences it. flags_0 is 0xFF about a third
//! of the time, otherwise a mix of edge values. The actor (an arena
//! vs_battle_actor2) gets edge values for unk954 (wrap), weapon.unk10B and the
//! unk956_2 bitfield. The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800859B4));

pub const classes = [_][:0]const u8{ "no-op", "in-range-index", "bound-0x36", "flags-ff", "flags-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg2 = ctx.edge(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });

    const arg0: c_uint = if (arg2 == 0)
        ctx.pick(c_uint, &.{ 0x16, 0x35, 0x36, 0xFFFF_FFFF, 0 })
    else if (ctx.chance(4))
        ctx.range(c_uint, 0, 255)
    else
        ctx.edge(c_uint, &.{ 0x15, 0x16, 0x17, 0x34, 0x35, 0x36, 0x37, 0, 0xFF });

    // The C reads flags_0 of vs_main_actions[arg0] only when arg2 != 0 and the
    // index is past the bound check; keep those reads inside the 256-entry array.
    const actions = v.g.actions();
    if (arg0 < 256) {
        actions[arg0].flags_0 = if (ctx.chance(3)) 0xFF else ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFE });
    }

    const actor = ctx.alloc(v.vs_battle_actor2);
    actor.unk954 = ctx.pick(u16, &.{ 0, 0xFFFF, 0x8000, 0x00FF });
    actor.weapon.unk10B = ctx.pick(u8, &.{ 0, 0xFF, 0x80 });
    psx.setBits(actor, "unk956_2", ctx.pick(u6, &.{ 0, 63 }));

    // The C never dereferences arg1 when arg2 is 0, so null is safe there.
    const arg1: ?*v.vs_battle_actor2 = if (arg2 == 0 and ctx.chance(2)) null else actor;
    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    if (args[2] == 0) return 0;
    const arg0 = args[0];
    if ((arg0 -% 0x16) < 0x20) return 1;
    if (arg0 == 0x36) return 2;
    return if (v.g.actions()[arg0].flags_0 == 0xFF) 3 else 4;
}
