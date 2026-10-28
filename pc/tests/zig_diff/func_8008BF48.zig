//! zig_diff spec: func_8008BF48 -> func_8008BF48.func_8008BF48 (146C.c).
//! Inputs: one _mpdRoomSectionA argument, either a fresh arena object or an
//! element of a 16-entry arena array (so it may alias the target the C
//! indexes). The room's sectionA global points at the array's element 0, and
//! the array has 4 entries before and 4 after the indexable range, so
//! unk10 runs from -4 to 11 with -1 (no target) common. The argument's unkE
//! is zero half the time, otherwise nonzero with and without the sign bit.
//! The target's unkA is zero, 1, 0x80 or 0xFF and its unkE zero or nonzero
//! with and without the sign bit. The stubs write the argument's unk10 (in
//! range) and fields of the objects they are passed, so the C's reads after
//! each call see what the callee left.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008BF48));

const Sec = v._mpdRoomSectionA;

pub const classes = [_][:0]const u8{
    "no-target-unkE0",
    "no-target-unkE-nonzero",
    "inactive-target-unkE0",
    "inactive-target-unkE-nonzero",
    "active-target-unkE0",
    "active-target-unkE-nonzero",
};

/// Start of the 16-entry array; the C's temp_s0 is `arr_ptr + 4`.
var arr_ptr: [*]Sec = undefined;
/// The argument of the current run, for the stubs to write back into.
var arg_ptr: ?*Sec = null;

/// A unk10 value that keeps the C's indexing inside the array.
fn inRangeIndex(ctx: *zd.Ctx) i16 {
    return @as(i16, @intCast(ctx.value(u8) % 16)) - 4;
}

pub const stubs = struct {
    pub fn func_8009291C(ctx: *zd.Ctx, lock: anytype) c_int {
        _ = lock;
        if (ctx.value(u1) == 1) arr_ptr[0].unk0.unkA = ctx.value(u8);
        if (ctx.value(u1) == 1) {
            if (arg_ptr) |a| a.unk10 = inRangeIndex(ctx);
        }
        return ctx.value(c_int);
    }

    pub fn func_8008BD74(ctx: *zd.Ctx, p: anytype) void {
        const a: *Sec = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) a.unk12 = ctx.value(u8);
        if (ctx.value(u1) == 1) a.unkE = ctx.value(i16);
        if (ctx.value(u1) == 1) a.unk10 = inRangeIndex(ctx);
    }

    pub fn func_8008C070(ctx: *zd.Ctx, lvl: anytype, p: anytype) void {
        _ = lvl;
        const a: *Sec = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) a.unk10 = inRangeIndex(ctx);
        if (ctx.value(u1) == 1) a.unkE = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const raw = ctx.allocBytes(@sizeOf(Sec) * 16, 16);
    arr_ptr = @ptrCast(@alignCast(raw));
    const base = arr_ptr + 4;

    const rd = v.g.vs_battle_roomData();
    psx.put(&rd.sectionA, &base[0]);

    const arg0: *Sec = if (ctx.chance(3))
        &arr_ptr[ctx.range(usize, 4, 15)]
    else
        ctx.alloc(Sec);
    arg_ptr = arg0;

    arg0.unkE = if (ctx.chance(2)) 0 else ctx.pick(i16, &.{ 1, -1, 0x7FFF, -32768, 0x100, -256 });
    arg0.unk10 = ctx.edge(i16, &.{ -1, -1, -1, -4, -3, -2, 0, 1, 2, 7, 11 });

    if (arg0.unk10 != -1) {
        const t = &arr_ptr[@intCast(@as(i32, arg0.unk10) + 4)];
        t.unk0.unkA = if (ctx.chance(3)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
        t.unkE = if (ctx.chance(2)) 0 else ctx.pick(i16, &.{ 1, -1, 0x7FFF, -32768 });
    }

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    const state: usize = if (a.unk10 == -1)
        0
    else if (arr_ptr[@intCast(@as(i32, a.unk10) + 4)].unk0.unkA == 0)
        1
    else
        2;
    return state * 2 + @as(usize, if (a.unkE == 0) 0 else 1);
}
