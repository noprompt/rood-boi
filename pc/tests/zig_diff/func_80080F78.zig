//! zig_diff spec: func_80080F78 -> func_80080F78.func_80080F78 (146C.c).
//! Inputs: an action whose type is the spell type 1 about a quarter of the
//! time (any 3-bit type otherwise), and a battle actor whose blade id is zero
//! a third of the time. arg2 and arg3 are each zero a third of the time and
//! otherwise an edge value: 1, 2, -1, INT_MIN, INT_MAX or a random int. The
//! three callees are recording stubs that write what the real ones can: the
//! blade's classes and affinities, the action's unk1, and the actor's unk957
//! (which the C reads back for the second call) and unk2E.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80080F78));

pub const classes = [_][:0]const u8{ "spell", "no-blade", "both", "class-only", "armor-only", "neither" };

/// Byte offset of unk957 from the blade (the blade sits inside the weapon).
const off_unk957: isize = @as(isize, @offsetOf(v.vs_battle_actor2, "unk957")) -
    @as(isize, @offsetOf(v.vs_battle_actor2, "weapon") + @offsetOf(v.vs_battle_uiWeapon, "blade"));

fn edgeInt(ctx: *zd.Ctx) c_int {
    if (ctx.chance(3)) return 0;
    return ctx.pick(c_int, &.{ 1, 2, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const actor = ctx.alloc(v.vs_battle_actor2);
    const t: u3 = if (ctx.chance(4)) 1 else ctx.range(u3, 0, 7);
    psx.setBits(action, "type", t);
    actor.weapon.blade.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &.{ 1, 0xFFFF, 0x8000 });
    const arg2 = edgeInt(ctx);
    const arg3 = edgeInt(ctx);
    return .{ action, actor, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    if (psx.getBits(action, "type") == 1) return 0;
    if (args[1].?.weapon.blade.id == 0) return 1;
    const a2 = args[2] != 0;
    const a3 = args[3] != 0;
    if (a2 and a3) return 2;
    if (a2) return 3;
    if (a3) return 4;
    return 5;
}

pub const stubs = struct {
    pub fn _triggerClassChange(ctx: *zd.Ctx, action: anytype, blade: anytype, idx: anytype, mask: anytype, unk: anytype) void {
        _ = idx;
        _ = mask;
        _ = unk;
        const act: *v.vs_action_t = @ptrCast(@alignCast(action orelse return));
        const eq: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(blade orelse return));
        if (ctx.value(u1) == 1) act.unk1 = ctx.value(u8);
        if (ctx.value(u1) == 1) eq.classes[ctx.value(u3)] = ctx.value(i8);
        if (ctx.value(u1) == 1) psx.byteAt(u8, eq, off_unk957).* = ctx.value(u8);
    }

    pub fn _triggerArmorAffinityChange(ctx: *zd.Ctx, action: anytype, blade: anytype, idx: anytype, mask: anytype, unk: anytype) void {
        _ = idx;
        _ = mask;
        _ = unk;
        const act: *v.vs_action_t = @ptrCast(@alignCast(action orelse return));
        const eq: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(blade orelse return));
        if (ctx.value(u1) == 1) act.unk1 = ctx.value(u8);
        if (ctx.value(u1) == 1) eq.affinities[ctx.value(u3)] = ctx.value(i8);
        if (ctx.value(u1) == 1) psx.byteAt(u8, eq, off_unk957).* = ctx.value(u8);
    }

    pub fn _calculateWeaponClassAffinity(ctx: *zd.Ctx, arg: anytype) void {
        const a: *v.vs_battle_actor2 = @ptrCast(@alignCast(arg orelse return));
        if (ctx.value(u1) == 1) a.unk957 = ctx.value(u8);
        if (ctx.value(u1) == 1) a.unk2E = ctx.value(u8);
    }
};
