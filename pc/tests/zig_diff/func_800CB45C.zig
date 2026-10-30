//! zig_diff spec: func_800CB45C -> func_800CB45C.func_800CB45C (5BF94.c).
//! Inputs: the name-window pointer null or not, text box 7 done or still busy,
//! the held flag zero or not (with and without the high bit), the timer over
//! 0-255 with 4 hit often (the `< 4` edge), and a tick speed that is often the
//! timer itself (so the timer reaches zero) or a small or negative edge (so it
//! wraps). The setTextBox stub rewrites the timer and the box's done bit
//! sometimes and returns any int.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB45C));

pub const classes = [_][:0]const u8{
    "no-window",
    "box-busy",
    "not-held",
    "held-low-timer",
    "held-ticking-down",
    "held-timer-reaches-zero",
};

pub const stubs = struct {
    pub fn vs_battle_setTextBox(ctx: *zd.Ctx, id: anytype, p: anytype) c_int {
        _ = id;
        _ = p;
        if (ctx.value(u1) == 1) v.g.nameWindowTimer().* = ctx.value(u8);
        if (ctx.value(u2) == 0) psx.setBits(&v.g.textBoxes()[7].unk0, "done", ctx.value(u1));
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const window = v.g.nameWindowText();
    if (ctx.chance(6)) {
        window.* = null;
    } else {
        const block: [*]i32 = @ptrCast(@alignCast(ctx.allocBytes(16, 4)));
        window.* = block;
    }

    psx.setBits(&v.g.textBoxes()[7].unk0, "done", if (ctx.chance(3)) 0 else 1);

    v.g.nameWindowHeld().* = if (ctx.chance(4)) 0 else ctx.pick(u8, &.{ 1, 2, 3, 4, 0x80, 0xFF });

    const timer = ctx.pick(u8, &.{ 0, 1, 2, 3, 4, 4, 5, 255 });
    v.g.nameWindowTimer().* = timer;

    // edge only: a random i32 here could overflow `timer - tick` (UB in the C).
    const tick: i32 = if (ctx.chance(3))
        @as(i32, timer)
    else
        ctx.edge(i32, &.{ 0, 1, 2, 3, 4, 5, 16, 255, 256, 1000, -1, -256 });
    v.g.vs_gametime_tickspeed().* = tick;

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (v.g.nameWindowText().* == null) return 0;
    const tb = &v.g.textBoxes()[7].unk0;
    if (psx.getBits(tb, "done") == 0) return 1;
    if (v.g.nameWindowHeld().* == 0) return 2;
    const timer = v.g.nameWindowTimer().*;
    if (timer < 4) return 3;
    const left = @as(i32, timer) - v.g.vs_gametime_tickspeed().*;
    return if (left == 0) 5 else 4;
}
