//! zig_diff spec: func_8007647C -> func_8007647C.func_8007647C (146C.c).
//! Inputs: an actor from the vs_battle_actors table (arg0 in 0..15) whose stats
//! block sits in the arena, and arg1 across the edges of `arg1 & 0xFF`: case 1
//! (with its call), cases 2 and 4 (the fall-through), and default (0x00, 0x03,
//! 0x81, 0x101, 0x102, -1 and friends, so a wider mask is caught). The
//! bzero stub zeroes the stats block, and the call stub writes a byte of the
//! actor. The C reads D_8004FDD0[0..23], four bytes past its 20-entry table:
//! those bytes are the harness's gap, so the copy sees whatever it holds.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007647C));

pub const classes = [_][:0]const u8{ "case-1", "case-2", "case-4", "default" };

pub const stubs = struct {
    /// Zeroes the bytes it is given, as the real routine does.
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        if (p) |q| {
            const bytes: [*]u8 = @ptrCast(q);
            @memset(bytes[0..@intCast(n)], 0);
        }
    }

    /// The callee may change the actor it was given (arg0's table entry); the
    /// C does not read that byte back, but the call-time state hash does.
    pub fn func_80095B7C(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = b;
        const p = v.g.vs_battle_actors()[@intCast(a)] orelse return;
        p.unk26 = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const idx = ctx.range(c_int, 0, 15);
    v.g.vs_battle_actors()[@intCast(idx)] = actor;
    // The C dereferences the stats pointer without a null test: always valid.
    psx.put(&actor.stats, stats);
    const sel = ctx.pick(c_int, &.{ 1, 2, 4, 0x101, 0x81, 0x102, 0x104, -1, 0, 3, 0x100 });
    return .{ idx, sel };
}

pub fn classify(args: Args) usize {
    return switch (args[1] & 0xFF) {
        1 => 0,
        2 => 1,
        4 => 2,
        else => 3,
    };
}
