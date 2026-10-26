//! zig_diff spec: func_80080C9C -> func_80080C9C.func_80080C9C (146C.c).
//! Inputs: an action whose unk2_4 selects one of the switch groups (1-4, 5/7/14,
//! 6/8/11/12, or none of them), an actor2 whose unk957 indexes a registered
//! vs_battle_actors entry (0-15) with random weaponDrawn, a shield and six limbs
//! whose maxHp and armor id are zero or not (sometimes all empty, so nothing is
//! eligible), and arg2/arg3/arg4 with zero, negative and limb-index edges. arg4
//! of 6 and 7 reads past the limb array; arg4 of 255, 256, 300 and 511 reads
//! limbs far past it, inside the arena, with a positive index above 255 that the
//! C can select as temp_s2. The getRand stub picks a candidate uniformly (and
//! returns 0 for a non-positive count, as the mutated callers ask for), and
//! sometimes clears the shield or a limb's armor id, so the trigger-time guards
//! are reachable. The trigger and affinity callees are recording stubs that write
//! their equipment or unit, so a port that caches a value across a call, or drops
//! a call, diverges.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80080C9C));

pub const classes = [_][:0]const u8{ "switch-none", "case-1-4", "case-5-7-14", "case-6-8-11-12" };

/// The actor2 of the current input, for the getRand stub (set by prepare).
var actor2_seen: ?*v.vs_battle_actor2 = null;

fn asPtr(comptime T: type, p: anytype) *T {
    const q = if (comptime @typeInfo(@TypeOf(p)) == .optional) p.? else p;
    return @ptrCast(@alignCast(q));
}

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: c_int) c_int {
        // The RNG cannot change the unit, but the C's guards after it must
        // still be reachable: sometimes clear the shield or one limb's armor.
        if (actor2_seen) |a| {
            if (ctx.value(u2) == 0) a.shield.base.id = 0;
            if (ctx.value(u2) == 0) a.limbs[ctx.value(u3) % 6].armor.armor.id = 0;
        }
        if (n <= 0) return 0;
        const m: u32 = @intCast(n);
        return @intCast(ctx.value(u32) % m);
    }

    pub fn _triggerClassChange(ctx: *zd.Ctx, action: anytype, equipment: anytype, cls: anytype, name: anytype, unit: anytype) void {
        _ = action;
        _ = cls;
        _ = name;
        _ = unit;
        const eq = asPtr(v.vs_battle_uiEquipment, equipment);
        eq.classes[ctx.value(u3)] = ctx.value(i8);
        if (ctx.value(u2) == 0) eq.id = 0;
    }

    pub fn _triggerWeaponAffinityChange(ctx: *zd.Ctx, action: anytype, equipment: anytype, cls: anytype, name: anytype, unit: anytype) void {
        _ = action;
        _ = cls;
        _ = name;
        _ = unit;
        const eq = asPtr(v.vs_battle_uiEquipment, equipment);
        eq.affinities[ctx.value(u3)] = ctx.value(i8);
        if (ctx.value(u2) == 0) eq.id = 0;
    }

    pub fn _calculateShieldClassAffinity(ctx: *zd.Ctx, unit: anytype) void {
        const u = asPtr(v.vs_battle_actor2, unit);
        u.shield.currentDp = ctx.value(u16);
    }

    pub fn _calculateArmorClassAffinity(ctx: *zd.Ctx, unit: anytype, idx: anytype) void {
        const u = asPtr(v.vs_battle_actor2, unit);
        if (idx >= 0 and idx < 6) u.limbs[@intCast(idx)].armor.currentDp = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room below the actor2 for negative limb indices.
    _ = ctx.allocBytes(256, 16);
    const action = ctx.alloc(v.vs_action_t);
    const actor2 = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    actor2_seen = actor2;

    psx.setBits(action, "unk2_4", ctx.pick(u4, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 14 }));

    const idx = ctx.range(u8, 0, 15);
    actor2.unk957 = idx;
    v.g.vs_battle_actors()[idx] = actor;
    actor.weaponDrawn = ctx.pick(i32, &.{ 0, 1, -1, 2, 0x7FFF_FFFF, -0x8000_0000, 256 });

    actor2.shield.base.id = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    for (&actor2.limbs) |*limb| {
        limb.maxHp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
        limb.armor.armor.id = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    }
    if (ctx.chance(4)) {
        // Nothing eligible: the C returns early (or the fall-through test fails).
        for (&actor2.limbs) |*limb| limb.maxHp = 0;
        actor2.shield.base.id = 0;
    }

    const arg2 = ctx.pick(c_int, &.{ 0, 1, 2, -1 });
    const arg3 = ctx.pick(c_int, &.{ 0, 1, 2, -1 });
    const arg4 = ctx.edge(c_int, &.{ 0, 1, 2, 3, 4, 5, -1, -2, -3, 6, 7, 255, 256, 300, 511 });

    // Above the limb array, the limb at arg4 is a real object in the arena:
    // make it eligible so the C selects arg4 (a positive index above 255 is then
    // compared with 0xFF) in the groups that read limbs[arg4].
    if (arg4 > 5) {
        const limbs: [*]v.vs_battle_uiEquipment_limb = @ptrCast(&actor2.limbs[0]);
        const k: usize = @intCast(arg4);
        limbs[k].maxHp = 5;
        limbs[k].armor.armor.id = 7;
    }

    return .{ action, actor2, arg2, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    return switch (psx.getBits(action, "unk2_4")) {
        1, 2, 3, 4 => 1,
        5, 7, 14 => 2,
        6, 8, 11, 12 => 3,
        else => 0,
    };
}
