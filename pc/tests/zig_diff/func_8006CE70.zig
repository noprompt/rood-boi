//! zig_diff spec: func_8006CE70 -> func_8006CE70.func_8006CE70 (146C.c).
//! Inputs: an arg with a random unk0/unk4 and an unk6 whose & 0x1F0 selects
//! case 0x10, case 0x20/0x100 or the default (0x00, 0x30, 0x80, 0x180, 0x1F0),
//! with random bits outside 0x1F0 and a random low nibble (the index, 0-15).
//! Two 16-entry tables in the arena: the lock table (state drawn from 0-5 and
//! 255) and the counter table (unkC drawn from -2..5 and the i16 extremes).
//! The stubs return the tables (never null) and rewrite a random subset of
//! their entries, since the C re-reads them after the call. func_8007F434
//! returns zero a quarter of the time and any 32-bit value otherwise;
//! vs_battle_getStateFlag returns zero a quarter of the time and any byte
//! otherwise; func_80093B04 writes arg0->unk4 (the C never reads it back).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8006CE70));

pub const classes = [_][:0]const u8{
    "other-case",
    "lock-in-range",
    "lock-out-of-range",
    "counter-in-range",
    "counter-out-of-range",
};

var lock_arr: [*]v._mpdRoomSectionA = undefined;
var counter_arr: [*]v._mpdRoomSection13 = undefined;

pub const stubs = struct {
    pub fn func_8008E3B8(ctx: *zd.Ctx, arg0: anytype) [*c]v._mpdRoomSectionA {
        _ = arg0;
        for (0..16) |i| {
            if (ctx.value(u1) == 1) lock_arr[i].unk0.unk8.lock.state = ctx.value(u8);
        }
        return @ptrCast(lock_arr);
    }

    pub fn func_8008E370(ctx: *zd.Ctx, arg0: anytype) ?*v._mpdRoomSection13 {
        _ = arg0;
        for (0..16) |i| {
            if (ctx.value(u1) == 1) counter_arr[i].unkC = ctx.value(i16);
        }
        return &counter_arr[0];
    }

    pub fn func_8007F434(ctx: *zd.Ctx) c_int {
        const x = ctx.value(c_int);
        return if (ctx.value(u2) == 0) 0 else x;
    }

    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, flag: anytype) u8 {
        _ = flag;
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(u8);
    }

    pub fn func_80093B04(ctx: *zd.Ctx, p: anytype) void {
        const a: *v.func_8006CE70_t = @ptrCast(@alignCast(p.?));
        a.unk4 = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.func_8006CE70_t);
    arg.unk0 = ctx.int(i32);
    arg.unk4 = ctx.int(i16);

    const mask = ctx.edge(u16, &.{ 0x10, 0x20, 0x100, 0x00, 0x30, 0x1F0, 0x80, 0x180 });
    const hi = ctx.int(u16) & ~@as(u16, 0x1F0);
    const low = ctx.int(u4);
    arg.unk6 = @bitCast(hi | mask | low);

    lock_arr = @ptrCast(@alignCast(ctx.allocBytes(16 * @sizeOf(v._mpdRoomSectionA), 16)));
    counter_arr = @ptrCast(@alignCast(ctx.allocBytes(16 * @sizeOf(v._mpdRoomSection13), 16)));
    for (0..16) |i| {
        lock_arr[i].unk0.unk8.lock.state = ctx.pick(u8, &.{ 0, 1, 2, 3, 4, 5, 255 });
        counter_arr[i].unkC = ctx.pick(i16, &.{ 0, 1, 2, 3, 4, 5, -1, -2, 32767, -32768 });
    }

    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0].?;
    const u: u16 = @bitCast(arg.unk6);
    const k: usize = u & 0xF;
    return switch (u & 0x1F0) {
        0x10 => blk: {
            const s = lock_arr[k].unk0.unk8.lock.state;
            break :blk if (s >= 2 and s < 4) 1 else 2;
        },
        0x20, 0x100 => blk: {
            const c = counter_arr[k].unkC;
            break :blk if (c >= 2 and c < 4) 3 else 4;
        },
        else => 0,
    };
}
