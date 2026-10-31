//! zig_diff spec: _setArtAndAbilityToUnlock -> set_art_and_ability_to_unlock.setArtAndAbilityToUnlock (5BF94.c).
//! The C is two global stores and one call, so there are no branches or value edges to reach.
//! Inputs: `art` and `battleAbility` as any c_int, with edges (0, 1, -1, 255, 256, INT_MAX, INT_MIN)
//! half the time, so the u8 truncation of both stores is exercised. The callee func_800CACD0 is a
//! stub that sometimes overwrites vs_battle_unlockedBreakArt and returns an arbitrary int. A port
//! that stores after the call, or swaps the two stores, changes the state hashed at the call or the
//! final bytes.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setArtAndAbilityToUnlock));

pub const classes = [_][:0]const u8{ "both-in-byte", "art-out-of-byte", "ability-out-of-byte" };

pub const stubs = struct {
    pub fn func_800CACD0(ctx: *zd.Ctx, menuState: c_int, arg1: c_int) c_int {
        _ = menuState;
        _ = arg1;
        // The real callee can change the break-art unlock the C stored just before the call.
        if (ctx.value(u1) == 1) v.g.vs_battle_unlockedBreakArt().* = ctx.value(u8);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{
        ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFF_FFFF, -2147483648 }),
        ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFF_FFFF, -2147483648 }),
    };
}

pub fn classify(args: Args) usize {
    const art_in = args[0] >= 0 and args[0] <= 255;
    const ability_in = args[1] >= 0 and args[1] <= 255;
    if (art_in and ability_in) return 0;
    if (!art_in) return 1;
    return 2;
}
