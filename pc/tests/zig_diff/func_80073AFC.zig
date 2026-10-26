//! zig_diff spec: func_80073AFC -> func_80073AFC.func_80073AFC (146C.c).
//! Inputs: a room section whose gate (unkE, unk12) is open or shut, a lock
//! state of 0-3, keyOrSigil around chamomileSigil (466) with negative and
//! extreme values, and unk0 values that overflow the `<< 7` into sp10.
//! The inventory and state-flag stubs return zero and nonzero values (with
//! the sign bit set and clear). The func_8009E070 stub logs sp10[0] and
//! sp10[2], the only entries the C writes. Lock states 4-255 are not built:
//! the C leaves `template` uninitialised there, so its trace would not be
//! comparable.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073AFC));

pub const classes = [_][:0]const u8{ "gate-closed", "lock-0", "lock-2", "lock-1-3-sigil", "lock-1-3-key" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const sec = ctx.alloc(v._mpdRoomSectionA);
    sec.unk0.unk0 = ctx.pick(i16, &.{ 0, 1, -1, 0x0200, 0x0201, 32767, -32768 });
    sec.unk0.unk2 = ctx.pick(i16, &.{ 0, 1, -1, 0x0200, 0x0201, 32767, -32768 });
    sec.unk0.unk8.lock.state = ctx.edge(u8, &.{ 0, 1, 2, 3 });
    sec.unkE = if (ctx.chance(4)) ctx.pick(i16, &.{ 1, -1, 32767, -32768 }) else 0;
    sec.unk12 = if (ctx.chance(4)) ctx.pick(u8, &.{ 1, 128, 255 }) else 0;
    sec.keyOrSigil = ctx.pick(i16, &.{ 466, 465, 467, 0, -1, 32767, -32768 });
    return .{sec};
}

pub fn classify(args: Args) usize {
    const s = args[0].?;
    if (s.unkE != 0 or s.unk12 != 0) return 0;
    return switch (s.unk0.unk8.lock.state) {
        0 => 1,
        2 => 2,
        else => if (s.keyOrSigil >= 466) 3 else 4,
    };
}

pub const stubs = struct {
    pub fn vs_battle_itemIdIsInInventory(ctx: *zd.Ctx, id: anytype) c_int {
        _ = id;
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }

    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, id: anytype) u8 {
        _ = id;
        if (ctx.value(u1) == 0) return 0;
        return ctx.value(u8);
    }

    pub fn func_8009E070(ctx: *zd.Ctx, a: anytype, p: anytype, n: anytype) void {
        _ = a;
        _ = n;
        const s: *[4]c_short = @ptrCast(@alignCast(p));
        const log = ctx.alloc([2]c_short);
        log.* = .{ s[0], s[2] };
    }
};
