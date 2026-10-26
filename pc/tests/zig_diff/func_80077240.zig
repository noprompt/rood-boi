//! zig_diff spec: func_80077240 -> func_80077240.func_80077240 (146C.c).
//! Inputs: the actor slot arg0 is 0-15 (10 and 11-15 hit the high-index
//! return), occupied or empty; the blade id is 0, a sign-bit value, a value
//! equal to a _wepIdCategories entry, or one that no entry reaches, so the
//! search loop breaks early, breaks on an equal entry, or runs to 11; arg1 is
//! 0x7F about a third of the time (the equip calls are skipped). The
//! allocator hands out arena blocks; the callees write the fields the C reads
//! back (the equipped weapon category). arg0 stays in 0-15 so the C's
//! unconditional vs_battle_actors[arg0] read stays inside its table.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80077240));

pub const classes = [_][:0]const u8{ "occupied", "high-index", "no-blade", "blade-found", "blade-not-found", "no-equip" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = if (ctx.chance(3)) 10 else ctx.range(c_int, 0, 15);
    const actors = v.g.vs_battle_actors();
    actors[@as(usize, @intCast(arg0))] = if (ctx.chance(4)) ctx.alloc(v.vs_battle_actor) else null;

    const arg1: c_int = if (ctx.chance(3)) 0x7F else ctx.pick(c_int, &.{ 0, 1, 0x7E, 0x80, -1 });

    const cats = v.g._wepIdCategories();
    var k: usize = 1;
    while (k < 11) : (k += 1) cats[k] = ctx.int(u8);
    var blade: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, std.math.maxInt(c_int), std.math.minInt(c_int) });
    if (ctx.chance(3)) blade = @as(c_int, cats[ctx.range(usize, 1, 10)]);

    const bladeMaterial: c_int = ctx.int(c_int);
    const shieldWepId: c_int = ctx.pick(c_int, &.{ 0, 1, 2, -1 });
    const shieldMaterial: c_int = ctx.int(c_int);
    const arg6: ?*v.vs_battle_objectData_flags = if (ctx.chance(2)) null else ctx.alloc(v.vs_battle_objectData_flags);
    const arg7: c_int = ctx.pick(c_int, &.{ 0, 1, -1, 0x7F });

    return .{ arg0, arg1, blade, bladeMaterial, shieldWepId, shieldMaterial, arg6, arg7 };
}

pub fn classify(args: Args) usize {
    const idx: usize = @intCast(args[0]);
    if (v.g.vs_battle_actors()[idx] != null) return 0;
    if (args[0] >= 10) return 1;
    if (args[1] == 0x7F) return 5;
    if (args[2] == 0) return 2;
    const cats = v.g._wepIdCategories();
    var i: usize = 1;
    while (i < 11) : (i += 1) {
        if (@as(c_int, cats[i]) >= args[2]) return 3;
    }
    return 4;
}

pub const stubs = struct {
    pub fn vs_main_allocHeap(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        return @ptrCast(ctx.allocBytes(@as(usize, size), 16));
    }

    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const bytes: [*]u8 = @ptrCast(p.?);
        @memset(bytes[0..@as(usize, @intCast(n))], 0);
    }

    pub fn func_80077078(ctx: *zd.Ctx, arg0: anytype, index: anytype, wepId: anytype, arg3: anytype, arg4: anytype) c_int {
        _ = index;
        _ = wepId;
        _ = arg3;
        _ = arg4;
        const a: *v.vs_battle_actor = @ptrCast(@alignCast(arg0.?));
        a.equippedWeaponCategory = ctx.value(u8);
        return ctx.value(c_int);
    }

    pub fn func_800770FC(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
        _ = arg1;
        const a: *v.vs_battle_actor = @ptrCast(@alignCast(arg0.?));
        a.unk2A = ctx.value(u8);
    }

    pub fn func_80077130(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype, arg3: anytype, arg4: anytype) void {
        _ = arg1;
        _ = arg2;
        _ = arg3;
        _ = arg4;
        if (ctx.value(u1) == 1) {
            const a: *v.vs_battle_actor = @ptrCast(@alignCast(arg0.?));
            a.equippedWeaponCategory = ctx.value(u8);
        }
    }

    pub fn func_800771E0(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype, arg3: anytype) void {
        _ = arg1;
        _ = arg2;
        _ = arg3;
        const d: *v.vs_battle_actor_dat2 = @ptrCast(@alignCast(@as([*]u8, arg0)));
        d.unk0.unk0.defeated = ctx.value(u8);
    }
};
