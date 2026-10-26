//! zig_diff spec: func_8007D360 -> func_8007D360.func_8007D360 (146C.c).
//! The C takes no arguments, calls nothing and branches nowhere: it stores
//! constants into globals (the i32 pair D_800F1B98/D_800F1B9C, D_800F1A20,
//! the i16 table D_800F1A28, the i32 table D_800F1A30, the P_CODE struct
//! D_800F1A78, the u8 table D_800F1A9C, D_800F1A68, D_800F1A44, D_800F1A40).
//! The inputs are the random scratch state the harness gives every global,
//! so each run checks that every byte the C writes gets the same value and
//! every byte it leaves alone keeps its random value. Writes past a table's
//! declared room (D_800F1A28[2]) land in the harness-owned state regions, as
//! the C does. Nothing else is read, so one class covers the whole body.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D360));

pub const classes = [_][:0]const u8{"all"};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
