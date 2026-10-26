//! zig_diff spec: vs_battle_nop0 -> nop0.nop0 (146C.c).
//! The C body is empty: it reads nothing, makes no calls and stores nothing,
//! so there are no branches or value edges to reach. The input is one
//! vs_battle_actor2 in the arena, filled with random bytes. The harness
//! compares that object after both runs, so a port that writes it differs.
//! The pointer is never null: the mutations dereference it, and a null
//! argument would fault the C run. There is one input class, since the body
//! has no branch to split the inputs on.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").nop0));

pub const classes = [_][:0]const u8{"any-actor"};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor2);
    return .{actor};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
