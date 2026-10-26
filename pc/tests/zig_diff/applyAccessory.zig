//! zig_diff spec: vs_battle_applyAccessory -> apply_accessory.applyAccessory (146C.c).
//! Inputs: a target that is sometimes null (the C never tests it; the
//! callee stub does), and a source that is sometimes null (the C's only
//! branch). The heap block is an arena block the stub zeroes as bzero
//! would. The copy and apply callees write the state the C does not read
//! back, so a port that reorders or drops their calls is caught through
//! the call trace and the arena bytes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyAccessory));

pub const classes = [_][:0]const u8{ "no-source", "with-source" };

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        const n: usize = @intCast(size);
        return @ptrCast(ctx.allocBytes(n, 16));
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const raw: ?*anyopaque = p;
        const bytes: [*]u8 = @ptrCast(raw.?);
        const len: usize = @intCast(n);
        @memset(bytes[0..len], 0);
    }

    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        _ = ctx;
        _ = p;
    }

    pub fn vs_battle_copyInventoryArmorStats(ctx: *zd.Ctx, equip: anytype, source: anytype) void {
        _ = source;
        const raw: ?*anyopaque = equip;
        const e: *v.vs_battle_uiEquipment = @ptrCast(@alignCast(raw.?));
        e.id = ctx.value(u16);
        e.strength = ctx.value(i8);
        if (ctx.value(u1) == 1) e.currentDp = ctx.value(u16);
    }

    pub fn _applyAccessoryStats(ctx: *zd.Ctx, target: anytype, temp: anytype) void {
        const t_raw: ?*anyopaque = target;
        const tmp_raw: ?*anyopaque = temp;
        if (t_raw == null or tmp_raw == null) return;
        const t: *v.vs_battle_uiAccessory = @ptrCast(@alignCast(t_raw.?));
        const tmp: *v._accessoryIntermediate = @ptrCast(@alignCast(tmp_raw.?));
        t.index = tmp.index;
        t.currentStr = ctx.value(i16);
        if (ctx.value(u1) == 1) t.dropRate = tmp.dropRate;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiAccessory);
    const source = ctx.alloc(v.vs_main_inventoryArmor);
    source.index = ctx.int(u8);
    return .{
        if (ctx.chance(8)) null else target,
        if (ctx.chance(3)) null else source,
    };
}

pub fn classify(args: Args) usize {
    return if (args[1] == null) 0 else 1;
}
