//! zig_diff spec: vs_battle_applyArmor -> apply_armor.applyArmor (146C.c).
//! Inputs: a random uiArmor target (always valid) and an inventory armor that
//! is null a quarter of the time. The source's id, index and material are
//! random with edge values (material is a u16 narrowed into the u8 temp
//! field). The temp block comes from the arena through allocHeapR; bzero
//! zeroes it as the real one does, copyInventoryArmorStats writes the equip
//! block, and _applyArmorStats writes the target. The harness compares each
//! call's arguments, the state hash at each call (the temp block's bytes
//! included) and the final state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyArmor));

pub const classes = [_][:0]const u8{ "no-source", "source" };

/// The pointee of a stub argument, whether the C passes it optional or not.
fn ptrOf(comptime T: type, p: anytype) *T {
    return switch (@typeInfo(@TypeOf(p))) {
        .optional => @ptrCast(@alignCast(p.?)),
        else => @ptrCast(@alignCast(p)),
    };
}

pub const stubs = struct {
    /// The temp block: a fresh arena block (random bytes, zeroed by bzero).
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        return @ptrCast(ctx.allocBytes(@intCast(size), 16));
    }

    /// The real bzero zeroes the block; the stub must do the same.
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const bytes: [*]u8 = @ptrCast(ptrOf(u8, p));
        @memset(bytes[0..@intCast(n)], 0);
    }

    /// Writes the equip block from the source (the C reads it back in the port's
    /// hash comparison of the temp block at the next call).
    pub fn vs_battle_copyInventoryArmorStats(ctx: *zd.Ctx, equip: anytype, source: anytype) void {
        _ = source;
        const e = ptrOf(v.vs_battle_uiEquipment, equip);
        e.id = ctx.value(u16);
        e.strength = ctx.value(i8);
        e.gemSlots = ctx.value(u8);
    }

    /// Writes the target the real function fills in.
    pub fn _applyArmorStats(ctx: *zd.Ctx, target: anytype, temp: anytype) void {
        _ = temp;
        const t = ptrOf(v.vs_battle_uiArmor, target);
        t.currentDp = ctx.value(u16);
        t.dropRate = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiArmor);
    const source = ctx.alloc(v.vs_main_inventoryArmor);
    source.id = ctx.int(u8);
    source.index = ctx.pick(u8, &.{ 0, 255 });
    source.material = ctx.pick(u16, &.{ 0, 255, 256, 0xFFFF });
    if (ctx.chance(4)) return .{ target, null };
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
