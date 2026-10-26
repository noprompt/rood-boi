//! zig_diff spec: func_8007C0AC -> func_8007C0AC.func_8007C0AC (146C.c).
//! Inputs: 16 actors in the arena (the whole vs_battle_actors table), each with
//! a random weaponDrawn (both parities and both signs) and an allegiance that
//! is often 4 or 8, so the hold branch and its 4/8 short-circuit both run. The
//! root character state is either a separate object or aliases actor 0, so the
//! final weaponDrawn read sees the stores the C made before the call. arg0 is
//! 0 or a table index in 1..15; arg1 is 2 (the toggle path) or a selector with
//! zero, one, negative and sign-bit values. func_8009D934 writes the root
//! character's weaponDrawn sometimes, so a port that reads it before the call
//! differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C0AC));

pub const classes = [_][:0]const u8{ "toggle", "root-clear", "hold-4-or-8", "other-allegiance" };

pub const stubs = struct {
    pub fn func_8009D934(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        // The real callee may change the root character's weapon state, which
        // the C reads back after the call (the arg0 == 0 path).
        if (ctx.value(u1) == 1) {
            if (v.g.vs_battle_characterState().*) |ch| ch.weaponDrawn = ctx.value(i32);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const a = ctx.alloc(v.vs_battle_actor);
        a.weaponDrawn = ctx.pick(i32, &.{ 0, 1, -1, 2, 0x7fffffff, -2147483648 });
        a.allegiance = ctx.pick(u16, &.{ 0, 4, 8, 12, 0xFFFF });
        table[i] = a;
    }
    // The root character: aliases actor 0 half the time, so the store in the
    // arg0 == 0 path and the final read touch the same field.
    if (ctx.chance(2)) {
        v.g.vs_battle_characterState().* = table[0];
    } else {
        const root = ctx.alloc(v.vs_battle_actor);
        root.weaponDrawn = ctx.pick(i32, &.{ 0, 1, -1, 0x7fffffff, -2147483648 });
        v.g.vs_battle_characterState().* = root;
    }

    const arg0: c_int = if (ctx.chance(3)) 0 else ctx.range(c_int, 0, 15);
    const arg1: c_int = if (ctx.chance(3))
        2
    else
        ctx.edge(c_int, &.{ 0, 1, -1, 3, 0x7fffffff, -2147483648 });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    if (args[1] == 2) return 0;
    if (args[0] == 0) return 1;
    const a = v.g.vs_battle_actors()[@as(usize, @intCast(args[0]))].?;
    return if (a.allegiance == 4 or a.allegiance == 8) 2 else 3;
}
