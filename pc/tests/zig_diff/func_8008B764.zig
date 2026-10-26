//! zig_diff spec: func_8008B764 -> func_8008B764.func_8008B764 (146C.c).
//! Inputs: vs_battle_roomData's section3 (a grid of 4-byte cells in the arena,
//! or null), section12 (a 12-element array in the arena, or null), and the
//! collision map (always valid, its width and height any i16 but mostly 1..12).
//! width and height are often equal to the map's size (the `<` edges), arg2 is
//! often 2 (the `>= 2` edge), often negative (the signed read), and the map
//! size is sometimes negative (converted to a huge unsigned bound by the C).
//! The C calls nothing and only computes addresses, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B764));

pub const classes = [_][:0]const u8{
    "section3-null",
    "high-section12-null",
    "high-section12",
    "width-out",
    "height-out",
    "in-grid",
};

fn arr(ctx: *zd.Ctx, comptime T: type, n: usize) *T {
    return @ptrCast(@alignCast(ctx.allocBytes(@sizeOf(T) * n, @alignOf(T))));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const rd = v.g.vs_battle_roomData();

    const cms = ctx.alloc(v._mpdRoomCollisionMapSection);
    cms.width = if (ctx.chance(8)) ctx.pick(i16, &.{ -1, -32768, 32767 }) else ctx.range(i16, 1, 12);
    cms.height = if (ctx.chance(8)) ctx.pick(i16, &.{ -1, -32768, 32767 }) else ctx.range(i16, 1, 12);
    const cw: c_uint = @bitCast(@as(c_int, cms.width));
    const ch: c_uint = @bitCast(@as(c_int, cms.height));

    const width: c_uint = if (ctx.chance(4)) cw else ctx.range(c_uint, 0, 14);
    const height: c_uint = if (ctx.chance(4)) ch else ctx.range(c_uint, 0, 14);
    const arg2: c_int = if (ctx.chance(2))
        ctx.range(c_int, -3, 9)
    else
        ctx.pick(c_int, &.{ 0, 1, 2, 3, 9, -1, 2147483647, -2147483648 });

    const grid = arr(ctx, v._mpdRoomSection3, 256);
    const sec12 = arr(ctx, v._mpdRoomSection12, 12);
    psx.put(&rd.section3, if (ctx.chance(6)) null else grid);
    psx.put(&rd.section12, if (ctx.chance(4)) null else sec12);
    psx.put(&rd.collisionMapSection, cms);

    return .{ width, height, arg2 };
}

pub fn classify(args: Args) usize {
    const rd = v.g.vs_battle_roomData();
    if (psx.get(rd.section3) == null) return 0;
    if (args[2] >= 2) return if (psx.get(rd.section12) == null) 1 else 2;
    const cms = psx.get(rd.collisionMapSection).?;
    if (args[0] >= @as(c_uint, @bitCast(@as(c_int, cms.width)))) return 3;
    if (args[1] >= @as(c_uint, @bitCast(@as(c_int, cms.height)))) return 4;
    return 5;
}
