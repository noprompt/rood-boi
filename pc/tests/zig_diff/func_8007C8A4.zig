//! zig_diff spec: func_8007C8A4 -> func_8007C8A4.func_8007C8A4 (146C.c).
//! Inputs: arg0 mostly in 0..15 (each table slot a fresh actor, sometimes
//! null, sometimes with a null unk44 target), and arg0 in 16..23 (the C reads
//! the table past its 16 entries before its `arg0 < 16` test, so those reads
//! see the random fill; prepare never writes past slot 15). arg0 == 16 is
//! hit often (the bound's equal sides). arg1 is an edge or any int, and
//! reaches the callee unchanged. The callee is a recording stub: the C reads
//! nothing back after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C8A4));

pub const classes = [_][:0]const u8{ "table-null", "past-end", "unk44-null", "call" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const tbl = v.g.vs_battle_actors();
    // Slots 0..15 only: the table's 16 entries. Slots past them keep the random fill.
    for (0..16) |i| {
        if (ctx.chance(4)) {
            tbl[i] = null;
        } else {
            const actor = ctx.alloc(v.vs_battle_actor);
            const target: ?*v.D_800F4538_unk0 = if (ctx.chance(4)) null else ctx.alloc(v.D_800F4538_unk0);
            psx.put(&actor.unk44, target);
            tbl[i] = actor;
        }
    }
    const arg0: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 0, 1, 7, 14, 15, 16, 17, 23 })
    else
        ctx.range(c_int, 0, 15);
    const arg1: c_int = ctx.pick(c_int, &.{ 0, -1, 1, 0x7fffffff, -2147483648 });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const i = args[0];
    if (i >= 16) return 1;
    const actor = v.g.vs_battle_actors()[@intCast(i)] orelse return 0;
    if (psx.get(actor.unk44) == null) return 2;
    return 3;
}
