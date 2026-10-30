//! zig_diff spec: vs_battle_isSpellClassUnlocked -> is_spell_class_unlocked.isSpellClassUnlocked (5BF94.c).
//! Inputs: a spellClass in 0..19 (slots 4..19 have no id table, so their count is 0),
//! per-class counts of 0, 1, 2, 3, 255 and random bytes, id lists in 256-byte arena
//! buffers (any byte is a valid action index), and the unlocked bit of all 256 actions
//! set all-locked, all-unlocked or mixed. Covers the loop never entered, the loop run
//! to its end (i == count), an unlock found at some index, and a count above zero with
//! nothing unlocked. The C has no external calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").isSpellClassUnlocked));

pub const classes = [_][:0]const u8{ "count-zero", "found", "not-found", "slot-above-3" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const counts = v.g._spellClassCounts();
    const ids = v.g._spellIds();
    const acts = v.g.actions();

    // Every id list gets a 256-byte buffer, so any count (up to 255) reads inside it.
    for (0..4) |k| ids[k] = @ptrCast(ctx.allocBytes(256, 16));

    const slot: usize = if (ctx.chance(3)) ctx.range(u8, 4, 19) else ctx.range(u8, 0, 3);
    // Slots 4..19 have no id list: a count above zero would index past _spellIds.
    const count: u8 = if (slot >= 4) 0 else ctx.pick(u8, &.{ 0, 1, 2, 3, 255 });
    counts[slot] = count;

    const mode = ctx.range(u8, 0, 7);
    for (0..256) |a| {
        const on: u1 = switch (mode) {
            0...3 => 0,
            4 => 1,
            else => @intFromBool(ctx.chance(3)),
        };
        psx.setBits(&acts[a], "unlocked", on);
    }

    return .{@as(c_int, @intCast(slot))};
}

fn anyUnlocked(sc: usize, count: u8) bool {
    const ids: [*]u8 = @ptrCast(v.g._spellIds()[sc].?);
    const acts = v.g.actions();
    for (0..count) |i| {
        if (psx.getBits(&acts[ids[i]], "unlocked") != 0) return true;
    }
    return false;
}

pub fn classify(args: Args) usize {
    const sc: usize = @intCast(args[0]);
    const count = v.g._spellClassCounts()[sc];
    if (count == 0) return if (sc >= 4) 3 else 0;
    return if (anyUnlocked(sc, count)) 1 else 2;
}
