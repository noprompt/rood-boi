//! zig_diff spec: func_8007BCCC -> func_8007BCCC.func_8007BCCC (146C.c).
//! Inputs: the function takes no arguments and has no branches. Its inputs are the
//! global D_80050468, which the C overwrites with zeros before any read, so the
//! random pre-state only matters for the bytes it leaves alone (unk0, unk1, unk2).
//! The stubs for vs_battle_setStateFlag and func_800CB560 are void recording stubs.
//! Mutations change a store's value, drop a store or call, add a call, or change a
//! state-flag id; the call trace and the state hash at each call catch them.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BCCC));

pub const classes = [_][:0]const u8{"always"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
