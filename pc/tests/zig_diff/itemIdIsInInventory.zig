//! zig_diff spec: vs_battle_itemIdIsInInventory -> item_id_is_in_inventory.itemIdIsInInventory (146C.c).
//! Inputs: the category sizes (ascending small values, sometimes one with the
//! high bit set so the unsigned compare differs from a signed one) and an id
//! that is 0, negative, equal to a size, in a category, past the last size, or
//! in the unused category 3. The id is written into the inventory array of the
//! category it falls in (sometimes skipped, for misses), at an index that
//! favours the last entry, and misc counts are zero about a quarter of the time.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").itemIdIsInInventory));

pub const classes = [_][:0]const u8{ "zero", "negative", "equal-size", "past-end", "unused-category", "hit", "miss" };

/// The category the C's loop stops at: the first i with (unsigned)id < sizes[i], or 8.
fn categoryOf(id: c_int, sizes: [*]u32) usize {
    const ui: u32 = @bitCast(id);
    var i: usize = 0;
    while (i < 8 and !(ui < sizes[i])) : (i += 1) {}
    return i;
}

fn equalsSize(id: c_int, sizes: [*]u32) bool {
    const ui: u32 = @bitCast(id);
    for (0..8) |k| {
        if (sizes[k] == ui) return true;
    }
    return false;
}

fn inCategory(cat: usize, id: c_int) bool {
    const inv = v.g.vs_main_inventory();
    switch (cat) {
        0 => {
            for (inv.blades) |e| {
                if (@as(c_int, e.id) == id) return true;
            }
        },
        1 => {
            for (inv.grips) |e| {
                if (@as(c_int, e.id) == id) return true;
            }
        },
        2 => {
            for (inv.armor) |e| {
                if (@as(c_int, e.id) == id) return true;
            }
        },
        4 => {
            for (inv.gems) |e| {
                if (@as(c_int, e.id) == id) return true;
            }
        },
        5, 6, 7 => {
            for (inv.misc) |e| {
                if (@as(c_int, e.id) == id and e.count != 0) return true;
            }
        },
        else => {},
    }
    return false;
}

fn pickIndex(ctx: *zd.Ctx, n: usize) usize {
    return if (ctx.chance(3)) n - 1 else ctx.range(usize, 0, n - 1);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const sizes = v.g._itemCategorySizes();
    var acc: u32 = 0;
    for (0..8) |k| {
        acc += ctx.range(u32, 1, 12);
        sizes[k] = acc;
    }
    if (ctx.chance(5)) {
        sizes[ctx.range(usize, 0, 7)] = @as(u32, 0x8000_0000) | @as(u32, ctx.int(u31));
    }

    const id: c_int = switch (ctx.range(u8, 0, 9)) {
        0 => 0,
        1 => -@as(c_int, ctx.range(u8, 1, 200)),
        2 => @bitCast(sizes[ctx.range(usize, 0, 7)]),
        3 => ctx.range(c_int, 1, 100),
        4 => ctx.int(c_int),
        else => ctx.range(c_int, 1, 120),
    };

    const cat = categoryOf(id, sizes);
    const ui: u32 = @bitCast(id);
    const inv = v.g.vs_main_inventory();
    if (cat < 8 and cat != 3 and !ctx.chance(3)) {
        switch (cat) {
            0 => {
                inv.blades[pickIndex(ctx, 16)].id = @truncate(ui);
            },
            1 => {
                inv.grips[pickIndex(ctx, 16)].id = @truncate(ui);
            },
            2 => {
                inv.armor[pickIndex(ctx, 16)].id = @truncate(ui);
            },
            4 => {
                inv.gems[pickIndex(ctx, 48)].id = @truncate(ui);
            },
            else => {
                const e = &inv.misc[pickIndex(ctx, 64)];
                e.id = @truncate(ui);
                e.count = if (ctx.chance(4)) 0 else ctx.int(u8);
            },
        }
    }

    return .{id};
}

pub fn classify(args: Args) usize {
    const id = args[0];
    const sizes = v.g._itemCategorySizes();
    if (id == 0) return 0;
    if (id < 0) return 1;
    if (equalsSize(id, sizes)) return 2;
    const cat = categoryOf(id, sizes);
    if (cat == 8) return 3;
    if (cat == 3) return 4;
    return if (inCategory(cat, id)) 5 else 6;
}
