//! zig_diff spec: func_80089098 -> func_80089098.func_80089098 (146C.c).
//! Inputs: the three pointer fields of _zoneContext (zndEnemies, zudFiles,
//! mpdLbas), each null or pointing at a block in the arena, so the two
//! guarded frees run or not in every combination. func_800BEBEC is a stub
//! that rewrites those fields (the C reads them after the call), with
//! nulls drawn too. The frees and _vsBattleNop2 are recording calls; the
//! C never dereferences the pointers it frees.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089098));

pub const classes = [_][:0]const u8{
    "enemies-null/files-null",
    "enemies-null/files-set",
    "enemies-set/files-null",
    "enemies-set/files-set",
};

/// A pointer to a block of the arena at byte offset `off`, or null.
fn pick(comptime T: type, is_null: bool, off: usize) ?*T {
    if (is_null) return null;
    return block(T, off);
}

fn block(comptime T: type, off: usize) *T {
    return @ptrCast(@alignCast(&zd.zdiff_arena[off]));
}

pub const stubs = struct {
    pub fn func_800BEBEC(ctx: *zd.Ctx) void {
        const z = v.g._zoneContext();
        psx.put(&z.zndEnemies, pick(v._zndEnemy, ctx.value(u8) < 64, 4096));
        psx.put(&z.zudFiles, pick(v.vs_main_CdFile, ctx.value(u8) < 64, 8192));
        psx.put(&z.mpdLbas, pick(v.vs_main_CdFile, ctx.value(u8) < 128, 12288));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const z = v.g._zoneContext();
    psx.put(&z.zndEnemies, pick(v._zndEnemy, ctx.chance(4), 4096));
    psx.put(&z.zudFiles, pick(v.vs_main_CdFile, ctx.chance(2), 8192));
    psx.put(&z.mpdLbas, pick(v.vs_main_CdFile, ctx.chance(8), 12288));
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const z = v.g._zoneContext();
    const e = psx.get(z.zndEnemies) != null;
    const f = psx.get(z.zudFiles) != null;
    return (@as(usize, @intFromBool(e)) << 1) | @as(usize, @intFromBool(f));
}
