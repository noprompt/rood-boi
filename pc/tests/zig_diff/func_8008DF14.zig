//! zig_diff spec: func_8008DF14 -> func_8008DF14.func_8008DF14 (146C.c).
//! Inputs: the room's section 9 is null or points at up to six random
//! elements in the arena, with a section9Len of 0-5 whole elements plus an
//! occasional remainder. Each element has an unkA of 0 or not, and an unkB
//! from the edges 0, 1, 126-129, 255 (the signed-char sign test and the
//! decrement path) plus random bytes. unk6 hits 0x0F, 0x10, 0x11 and negatives.
//! The gate flags unk20/unk40 are zero about half the time. The tickspeed is
//! -1 to 4, so both loops are entered and skipped. D_800F1D6C is set so that
//! the increment reaches exactly 8 sometimes. The callees are recording
//! stubs: func_8008DC7C returns any short and may change D_800F1CDC;
//! func_8008E19C may change the unk40 gate and D_800F1D6C for the next element.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008DF14));

pub const classes = [_][:0]const u8{ "no-section9", "empty-section9", "gate-open", "gate-shut" };

pub const stubs = struct {
    pub fn func_8008DC7C(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) i16 {
        _ = arg0;
        _ = arg1;
        if (ctx.value(u1) == 1) v.g.D_800F1CDC().* = ctx.value(u16);
        return ctx.value(i16);
    }

    pub fn func_8008E19C(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype, arg3: anytype) void {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        _ = arg3;
        if (ctx.value(u1) == 1) {
            v.g.vs_main_stateFlags().unk40 = if (ctx.value(u1) == 1) 0 else ctx.value(u8);
        }
        if (ctx.value(u2) == 0) v.g.D_800F1D6C().* = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const flags = v.g.vs_main_stateFlags();
    const tick = v.g.vs_gametime_tickspeed();
    const d1d6c = v.g.D_800F1D6C();
    const cdc = v.g.D_800F1CDC();

    tick.* = ctx.edge(i32, &.{ -1, 0, 1, 1, 2, 2, 3, 4 });
    cdc.* = ctx.int(u16);
    d1d6c.* = if (ctx.chance(2))
        @as(u16, @truncate(@as(u32, @bitCast(8 - tick.*))))
    else
        ctx.pick(u16, &.{ 0, 1, 6, 7, 8, 0xFFFF });

    flags.unk20 = if (ctx.chance(4)) ctx.int(u8) else 0;
    flags.unk40 = if (ctx.chance(4)) ctx.int(u8) else 0;

    const sz: u32 = @sizeOf(v._mpdRoomSection9);
    const bytes = ctx.allocBytes(6 * @sizeOf(v._mpdRoomSection9), 16);
    const list: [*]v._mpdRoomSection9 = @ptrCast(@alignCast(bytes));
    for (0..6) |k| {
        const e = &list[k];
        e.unk0 = ctx.int(i16);
        e.unk2 = ctx.int(i16);
        e.unk6 = ctx.pick(i16, &.{ 0x0F, 0x10, 0x11, -1, 0x7FFF, -32768, 0 });
        e.unkA = ctx.pick(u8, &.{ 0, 1, 0xFF });
        e.unkB = ctx.pick(u8, &.{ 0, 1, 126, 127, 128, 129, 255 });
    }

    const count = ctx.range(u32, 0, 5);
    const rem: u32 = if (ctx.chance(4)) ctx.range(u32, 1, sz - 1) else 0;
    room.header.section9Len = count * sz + rem;
    const first: ?*v._mpdRoomSection9 = if (ctx.chance(8)) null else &list[0];
    psx.put(&room.section9, first);

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const room = v.g.vs_battle_roomData();
    if (psx.get(room.section9) == null) return 0;
    if (room.header.section9Len < @sizeOf(v._mpdRoomSection9)) return 1;
    const flags = v.g.vs_main_stateFlags();
    if (flags.unk20 == 0 and flags.unk40 == 0) return 2;
    return 3;
}
