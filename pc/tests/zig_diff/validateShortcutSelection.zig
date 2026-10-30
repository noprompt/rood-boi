//! zig_diff spec: vs_battle_validateShortcutSelection -> validate_shortcut_selection.validateShortcutSelection (5BF94.c).
//! Inputs: the shortcut across every switch arm (1-4, 5, 6, 7-8), the default arm
//! (0, 9, negatives, 257 which truncates to 1 in the u8 store), and random ints.
//! The unlock queries are recording stubs that return 0 (locked) a quarter of the
//! time and otherwise a nonzero value of either sign, so the `if (noneUnlocked)`
//! branch and both arms of each `== 0` test are taken. func_800CACD0 writes nothing
//! the C reads back (the C stores its own globals after the call), so its stub only
//! returns a value. The C reads no globals before writing them, so prepare builds
//! only the argument.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").validateShortcutSelection));

pub const classes = [_][:0]const u8{ "spell-classes", "menu-5", "break-arts", "chain", "other" };

pub const stubs = struct {
    /// The unlock queries: 0 (locked) a quarter of the time, else a nonzero value of either sign.
    fn unlockedResult(ctx: *zd.Ctx) c_int {
        if (ctx.value(u2) == 0) return 0;
        const x = ctx.value(c_int);
        return if (x == 0) 2 else x;
    }

    pub fn vs_battle_isSpellClassUnlocked(ctx: *zd.Ctx, spellClass: anytype) c_int {
        _ = spellClass;
        return unlockedResult(ctx);
    }

    pub fn _breakArtsUnlocked(ctx: *zd.Ctx) c_int {
        return unlockedResult(ctx);
    }

    pub fn vs_battle_chainAbilitiesUnlocked(ctx: *zd.Ctx, chain: anytype) c_int {
        _ = chain;
        return unlockedResult(ctx);
    }

    pub fn func_800CACD0(ctx: *zd.Ctx, menuState: anytype, arg1: anytype) c_int {
        _ = menuState;
        _ = arg1;
        return ctx.value(c_int);
    }

    pub fn vs_battle_playInvalidSfx(ctx: *zd.Ctx) void {
        _ = ctx;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(10)) return .{ctx.int(c_int)};
    return .{ctx.edge(c_int, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, 256, 257 })};
}

pub fn classify(args: Args) usize {
    return switch (args[0]) {
        1...4 => 0,
        5 => 1,
        6 => 2,
        7, 8 => 3,
        else => 4,
    };
}
