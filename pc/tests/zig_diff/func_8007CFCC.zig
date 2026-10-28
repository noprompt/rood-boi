//! zig_diff spec: func_8007CFCC -> func_8007CFCC.func_8007CFCC (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors (the table's 16 slots; only the
//! slot the C reads is set). The slot is null, an arena actor whose unk26 has
//! edge values (0, 1, 127, 128, 255), or an actor at PS1 address 0 (mapped at
//! 0x80000000, so its pointer has the sign bit set) with random unk26 bytes.
//! The C makes no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CFCC));

pub const classes = [_][:0]const u8{ "null-entry", "arena-entry", "lowram-entry" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const idx = ctx.range(c_int, 0, 15);
    const table = v.g.vs_battle_actors();
    const kind = ctx.range(u8, 0, 9);
    if (kind < 3) {
        table[@intCast(idx)] = null;
    } else if (kind < 7) {
        const actor = ctx.alloc(v.vs_battle_actor);
        actor.unk26 = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
        table[@intCast(idx)] = actor;
    } else {
        const low = psx.lowRam(v.vs_battle_actor);
        low.unk26 = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
        table[@intCast(idx)] = @ptrCast(@alignCast(low));
    }
    return .{idx};
}

pub fn classify(args: Args) usize {
    const p = v.g.vs_battle_actors()[@intCast(args[0])] orelse return 0;
    const a = @intFromPtr(p);
    return if (a >= zd.low_ram and a < zd.low_ram + zd.low_ram_size) 2 else 1;
}
