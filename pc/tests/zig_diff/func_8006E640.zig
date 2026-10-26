//! zig_diff spec: func_8006E640 -> func_8006E640.func_8006E640 (146C.c).
//! Inputs: the camera mode (1, 3, 2, 11, 4 and the no-op modes 0, 5, all
//! ones), the D_800F19CC block (a 17 KB arena object, so its unk29C0 table
//! can be indexed up to 255 although it has 23 entries, as the C allows),
//! unk298D at 0xFF and unk2C00 at 0 (the fallback), the func_800C4734 result
//! (1 or not), and the vy that func_800A1108 writes at the i16 wrap edges.
//! func_8006E158 may change unk298D/unk2C00. _stepTowardTarget records the
//! target it was given (vx, vy and vz) into the block, so the C and port
//! must agree on all three components of the target.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006E640));

pub const classes = [_][:0]const u8{ "table", "table-off", "step8", "step40", "mode11", "mode4", "other-mode" };

/// Set by prepare: the value func_800C4734 returns this iteration.
var step_ret: c_int = 0;
/// Set by prepare: the vy func_800A1108 writes into its out-parameter.
var in_vy: i16 = 0;

pub const stubs = struct {
    /// Fills the out-parameter's unk4 vector, which the C reads back.
    pub fn func_800A1108(ctx: *zd.Ctx, arg0: anytype, out: anytype) c_int {
        _ = arg0;
        const p: [*]u8 = @ptrCast(out.?);
        const sv: *align(1) v.SVECTOR = @ptrCast(p + 4);
        sv.vx = ctx.value(i16);
        sv.vy = in_vy;
        sv.vz = ctx.value(i16);
        return ctx.value(c_int);
    }

    /// The step result the C tests for ==1.
    pub fn func_800C4734(ctx: *zd.Ctx) c_int {
        _ = ctx;
        return step_ret;
    }

    /// Records the whole target it was given into the block, so each
    /// component the C chose is compared, not just two of them.
    pub fn _stepTowardTarget(ctx: *zd.Ctx, target: anytype, mode: anytype, speed: anytype) c_int {
        _ = mode;
        _ = speed;
        const d = v.g.D_800F19CC().*.?;
        d.unk2C0C = target.*.vx;
        d.unk2C0E = target.*.vy;
        d.unk2BE8 = target.*.vz;
        d.unk2BEC = target.*.vx;
        d.unk2BF0 = target.*.vy;
        return ctx.value(c_int);
    }

    /// Sometimes moves the table selector and the count the C reads back.
    pub fn func_8006E158(ctx: *zd.Ctx) void {
        if (ctx.value(u2) != 0) return;
        const d = v.g.D_800F19CC().*.?;
        d.unk298D = ctx.value(u8);
        d.unk2C00 = ctx.value(u16);
    }

    /// Writes one byte of the bitfield block the C never reads back.
    pub fn func_80074B14(ctx: *zd.Ctx, arg0: anytype, fields: anytype) void {
        _ = arg0;
        const p: [*]u8 = @ptrCast(fields.?);
        p[0] = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // 17408 bytes: the table at 0x29C0 is read up to index 255 (16832 bytes).
    const obj: *v.D_800F19CC_t = @ptrCast(@alignCast(ctx.allocBytes(17408, 16)));
    v.g.D_800F19CC().* = obj;
    v.g._cameraMode().* = ctx.edge(u32, &.{ 1, 2, 3, 4, 11, 0, 5, 0xFFFF_FFFF });
    obj.unk298D = ctx.pick(u8, &.{ 0, 1, 22, 23, 24, 0xFF, 0xFE, 128 });
    obj.unk2C00 = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    step_ret = ctx.edge(c_int, &.{ 1, 1, 0, 2, -1 });
    in_vy = ctx.pick(i16, &.{ -32768, -32679, -32678, -32677, -91, 0, 90, 32767 });
    return .{ctx.int(c_int)};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    return switch (v.g._cameraMode().*) {
        1, 3 => if (d.unk298D != 0xFF and d.unk2C00 != 0) 0 else 1,
        2 => if (step_ret == 1) 2 else 3,
        11 => 4,
        4 => 5,
        else => 6,
    };
}
