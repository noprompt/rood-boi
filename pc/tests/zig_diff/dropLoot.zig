//! zig_diff spec: _dropLoot -> drop_loot.dropLoot (146C.c).
//! Inputs: an enemy with a valid stats block (the C checks neither the enemy
//! nor the stats), its id from the edges and random, limb armor ids zero on
//! about a quarter of the limbs (so the armor loop skips them) and random
//! otherwise (both signs). The loot-list head is set per class: the heap
//! block is refused (lootList == NULL), all rolls return 0 (no drops), or the
//! rolls drop loot and the list is empty, holds the enemy's id already, or
//! holds other ids. The rolls are recording stubs that write the loot they are
//! passed, as the real callees do, and the heap block's bzero really zeroes it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropLoot));

pub const classes = [_][:0]const u8{
    "alloc-fails",
    "no-drops",
    "already-listed",
    "insert-empty-list",
    "insert-after-list",
};

// Set by prepare; the stubs read them (deterministic in both runs).
var alloc_fails: bool = false;
var no_drops: bool = false;
var mode: u8 = 0;
var block: ?*anyopaque = null;

pub fn prepare(ctx: *zd.Ctx) Args {
    const enemy = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    block = @ptrCast(ctx.allocBytes(@sizeOf(v.vs_battle_lootListNode), 16));
    psx.put(&enemy.stats, stats);
    enemy.id = ctx.pick(i32, &.{ 0, -1, 1, 0x7fff_ffff, -0x8000_0000 });
    for (&stats.limbs) |*limb| {
        if (ctx.chance(4)) limb.armor.armor.id = 0;
    }

    mode = ctx.range(u8, 0, 4);
    alloc_fails = mode == 0;
    no_drops = mode == 1;

    const count: usize = switch (mode) {
        2 => 2,
        3 => 0,
        4 => ctx.range(usize, 1, 3),
        else => ctx.range(usize, 0, 2),
    };
    var head: ?*v.vs_battle_lootListNode = null;
    for (0..count) |k| {
        const node = ctx.alloc(v.vs_battle_lootListNode);
        node.actorId = if (mode == 2 and k == 1) enemy.id else ctx.int(i32);
        psx.put(&node.next, head);
        head = node;
    }
    v.g._lootListHead().* = head;

    return .{enemy};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}

/// A pointer argument as bytes (the callee's loot or heap block).
fn bytes(p: anytype) [*]u8 {
    if (@typeInfo(@TypeOf(p)) == .optional) return @ptrCast(p.?);
    return @ptrCast(p);
}

/// The loot rolls: write the loot they are given and return a drop flag.
fn roll(ctx: *zd.Ctx, out: anytype) c_int {
    if (no_drops) return 0;
    const b = bytes(out);
    b[0] = ctx.value(u8);
    b[1] = ctx.value(u8);
    return ctx.value(c_int) | 1;
}

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = ctx;
        _ = size;
        if (alloc_fails) return null;
        return block;
    }

    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        _ = ctx;
        _ = p;
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const len: usize = @intCast(n);
        @memset(bytes(p)[0..len], 0);
    }

    pub fn _dropWeaponRand(ctx: *zd.Ctx, out: anytype, src: anytype) c_int {
        _ = src;
        return roll(ctx, out);
    }

    pub fn _dropShieldRand(ctx: *zd.Ctx, out: anytype, src: anytype) c_int {
        _ = src;
        return roll(ctx, out);
    }

    pub fn _dropAccessoryRand(ctx: *zd.Ctx, out: anytype, src: anytype) c_int {
        _ = src;
        return roll(ctx, out);
    }

    pub fn _dropArmorRand(ctx: *zd.Ctx, out: anytype, src: anytype) c_int {
        _ = src;
        return roll(ctx, out);
    }

    pub fn _dropMisc(ctx: *zd.Ctx, out: anytype, src: anytype) c_int {
        _ = src;
        return roll(ctx, out);
    }

    pub fn _dropMiscRand(ctx: *zd.Ctx, out: anytype, src: anytype) c_int {
        _ = src;
        return roll(ctx, out);
    }
};
