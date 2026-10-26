//! zig_diff spec: func_80079050 -> func_80079050.func_80079050 (146C.c).
//! Inputs: D_800F19CC points at a fresh arena block with a random unk0, so
//! the unk854 index (unk0 & 3) and the bits above it vary. func_800DEC88
//! returns 0, -1, 1 or another nonzero value (chosen per iteration by
//! prepare, so classify sees the same choice), and sometimes rewrites the
//! block it is handed. The two void callees are recording stubs: the C reads
//! nothing they could change after the call.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80079050));

/// Which value func_800DEC88 returns this iteration. Set by prepare, read by
/// the stub and by classify; the same in the C run and the Zig run.
var ret_mode: u2 = 0;

pub const classes = [_][:0]const u8{ "ret-zero", "ret-minus-one", "ret-one", "ret-other" };

pub const stubs = struct {
    pub fn func_800DEC88(ctx: *zd.Ctx, p: anytype) c_int {
        if (ctx.value(u1) == 1) {
            const a: *v.D_800F19CC_t2 = @ptrCast(@alignCast(p.?));
            a.actionIndex = ctx.value(u16);
        }
        return switch (ret_mode) {
            0 => 0,
            1 => -1,
            2 => 1,
            3 => ctx.value(c_int) | 1,
        };
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const block = ctx.alloc(v.D_800F19CC_t);
    block.unk0 = ctx.int(u32);
    block.unk4 = ctx.int(u32);
    v.g.D_800F19CC().* = block;
    ret_mode = ctx.int(u2);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return ret_mode;
}
