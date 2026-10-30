//! zig_diff spec: func_8008E320 -> func_8008E320.func_8008E320 (146C.c).
//! Inputs: vs_battle_roomData.section12 is either null or an arena array of 64
//! section-12 records. Element 8 is the C's element 0, so arg0 in [-8, 55]
//! stays inside the arena. The addressed record's unk4_0 flag is clear or set,
//! and its unk4_16 field is sampled across the sign bit (0, 1, 0x7FFF, 0x8000,
//! 0xFFFF) so a signed read of the 16-bit field shows.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E320));

pub const classes = [_][:0]const u8{ "section-null", "flag-clear", "flag-set-low", "flag-set-high" };

const count = 64;
const lead = 8;

pub fn prepare(ctx: *zd.Ctx) Args {
    const elems: [*]v._mpdRoomSection12 = @ptrCast(@alignCast(ctx.allocBytes(count * @sizeOf(v._mpdRoomSection12), 16)));
    const base: *v._mpdRoomSection12 = &elems[lead];

    const arg0: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ -8, -1, 0, 1, 55 })
    else
        ctx.range(c_int, -8, 55);
    const target: *v._mpdRoomSection12 = &elems[@intCast(lead + arg0)];

    psx.setBits(target, "unk4_0", if (ctx.chance(2)) 0 else 1);
    psx.setBits(target, "unk4_16", ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF }));

    const section: ?*v._mpdRoomSection12 = if (ctx.chance(5)) null else base;
    psx.put(&v.g.vs_battle_roomData().section12, section);

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const sec = psx.get(v.g.vs_battle_roomData().section12) orelse return 0;
    const rec = psx.at(sec, args[0]);
    if (psx.getBits(rec, "unk4_0") != 1) return 1;
    return if (psx.getBits(rec, "unk4_16") < 0x8000) 2 else 3;
}
