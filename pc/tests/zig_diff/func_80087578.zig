//! zig_diff spec: func_80087578 -> func_80087578.func_80087578 (146C.c).
//! Inputs: arg0 is a table index 0-15 (the C reads vs_battle_actors[arg0], a
//! 16-entry table, and the harness only owns that range), with 0 a third of
//! the time; the entry is always a valid arena actor whose unk27 is 0x80
//! half the time, so the `!= 0x80` test sees equal sides often and the `||`
//! reaches both of its operands. arg1..arg3 are any int. The callee
//! func_80093B68 is a recording stub: the C never reads anything back from
//! it, so it has no stub of its own.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80087578));

pub const classes = [_][:0]const u8{ "unk27-not-80", "unk27-80-arg0-zero", "unk27-80-arg0-nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    if (ctx.chance(2)) {
        actor.unk27 = 0x80;
    } else {
        actor.unk27 = ctx.pick(u8, &.{ 0x7F, 0x81, 0x00, 0xFF });
    }
    const arg0: c_int = if (ctx.chance(3)) 0 else ctx.range(c_int, 0, 15);
    v.g.vs_battle_actors()[@intCast(arg0)] = actor;
    return .{ arg0, ctx.int(c_int), ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[@intCast(args[0])].?;
    if (actor.unk27 != 0x80) return 0;
    return if (args[0] == 0) 1 else 2;
}
