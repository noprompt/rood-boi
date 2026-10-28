//! zig_diff spec: func_800704D8 -> func_800704D8.func_800704D8 (146C.c).
//! Inputs: a character actor whose weaponDrawn is drawn from edge values
//! covering both parities and the sign bit, and a D_800F19CC object (valid, as
//! the C dereferences it). The C has no branches: the classes split on the low
//! bit of weaponDrawn, which sets the argument of func_800CB660. The two
//! callees that can change state (func_800CAB40 writes the action index,
//! func_8006C39C rewrites weaponDrawn) are stubs that do so; func_800CB660 is
//! a recording void stub.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800704D8));

pub const classes = [_][:0]const u8{ "weapon-drawn-even", "weapon-drawn-odd" };

pub const stubs = struct {
    pub fn func_800CAB40(ctx: *zd.Ctx) void {
        if (v.g.D_800F19CC().*) |p| p.unk8.actionIndex = ctx.value(u16);
    }

    pub fn func_8006C39C(ctx: *zd.Ctx) void {
        if (v.g.vs_battle_characterState().*) |a| a.weaponDrawn = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const ch = ctx.alloc(v.vs_battle_actor);
    const dd = ctx.alloc(v.D_800F19CC_t);
    v.g.vs_battle_characterState().* = ch;
    v.g.D_800F19CC().* = dd;
    ch.weaponDrawn = ctx.pick(i32, &.{ 0, 1, 2, 3, -1, -2, 0x7fffffff, -0x80000000 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const ch = v.g.vs_battle_characterState().*.?;
    return if ((ch.weaponDrawn & 1) != 0) 1 else 0;
}
