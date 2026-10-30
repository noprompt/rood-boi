//! zig_diff spec: func_80073E30 -> func_80073E30.func_80073E30 (146C.c).
//! Inputs: an arena _mpdRoomSectionA with keyOrSigil 0, 1, 3 or another value,
//! random room coordinates (the `<< 7` and the store to short wrap), and unkE
//! around 0x1D2 and negative. prepare sets the state-flag and inventory answers
//! as spec vars, so every path is reached: case 0; case 1/3 with the flag set;
//! case 1/3 with the item not in the inventory (break, no store); case 1/3 with
//! the item taken, below and at or above 0x1D2. The message-log stub records
//! sp10[0] and sp10[2], the entries the C always sets (sp10[1] and sp10[3] are
//! uninitialised in the C, so they are not read).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073E30));

pub const classes = [_][:0]const u8{
    "key-zero",
    "other-key",
    "sigil-flagged",
    "sigil-not-in-inventory",
    "sigil-taken-low",
    "sigil-taken-high",
};

var flag_result: u8 = 0;
var inventory_result: c_int = 0;
var sp_log: ?*[2]c_short = null;

pub const stubs = struct {
    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, id: anytype) u8 {
        _ = ctx;
        _ = id;
        return flag_result;
    }

    pub fn vs_battle_itemIdIsInInventory(ctx: *zd.Ctx, id: anytype) c_int {
        _ = ctx;
        _ = id;
        return inventory_result;
    }

    // The callee rewrites the object it was given; the C never reads it back,
    // but the final state comparison sees it (catches a store moved across it).
    pub fn func_8008D5FC(ctx: *zd.Ctx, arg0: anytype) void {
        const a: *v._mpdRoomSectionA = @ptrCast(@alignCast(arg0));
        a.keyOrSigil = ctx.value(i16);
    }

    // Records the two scratchpad entries the C sets, into arena memory.
    pub fn func_8009E070(ctx: *zd.Ctx, a: anytype, p: anytype, n: anytype) void {
        _ = ctx;
        _ = a;
        _ = n;
        const src: [*]const c_short = @ptrCast(@alignCast(p));
        const log = sp_log.?;
        log[0] = src[0];
        log[1] = src[2];
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v._mpdRoomSectionA);
    sp_log = ctx.alloc([2]c_short);
    obj.unk0.unk0 = ctx.int(i16);
    obj.unk0.unk2 = ctx.int(i16);
    obj.keyOrSigil = ctx.edge(i16, &.{ 0, 1, 3, 0, 1, 3, 2, -1, 0x7FFF });
    obj.unkE = ctx.pick(i16, &.{ 0x1D1, 0x1D2, 0x1D2, 0x1D3, -1, 0x7FFF, -32768 });
    flag_result = ctx.pick(u8, &.{ 0, 0, 1, 0x80 });
    inventory_result = ctx.pick(c_int, &.{ 0, 0, 1, -1 });
    return .{ obj, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const obj = args[0].?;
    switch (obj.keyOrSigil) {
        0 => return 0,
        1, 3 => {},
        else => return 1,
    }
    if (flag_result != 0) return 2;
    if (inventory_result == 0) return 3;
    return if (obj.unkE >= 0x1D2) 5 else 4;
}
