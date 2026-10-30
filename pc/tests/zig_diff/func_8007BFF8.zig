//! zig_diff spec: func_8007BFF8 -> func_8007BFF8.func_8007BFF8 (146C.c).
//! Inputs: arg0 over the table's 16 slots, and each slot's pointer chosen as
//! null, a scratchpad address (nonzero, no sign bit), or a PS1 RAM address at
//! 0x80000000 (nonzero, sign bit set), so the `!= 0` test sees both kinds of
//! nonzero value. The two callees are default recording stubs returning any int.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BFF8));

pub const classes = [_][:0]const u8{ "null-entry", "nonzero-no-sign", "nonzero-sign-bit" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        table[i] = switch (ctx.range(u8, 0, 2)) {
            0 => @as(?*v.vs_battle_actor, null),
            1 => @as(?*v.vs_battle_actor, @ptrFromInt(zd.scratchpad + 4 * @as(usize, ctx.range(u8, 0, 255)))),
            else => @as(?*v.vs_battle_actor, @ptrFromInt(zd.low_ram + 4 * @as(usize, ctx.range(u16, 0, 1000)))),
        };
    }
    const arg0: c_int = @intCast(ctx.range(u8, 0, 15));
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const p = v.g.vs_battle_actors()[@intCast(args[0])] orelse return 0;
    return if ((@intFromPtr(p) & 0x8000_0000) != 0) 2 else 1;
}
