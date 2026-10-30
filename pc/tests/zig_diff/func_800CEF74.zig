//! zig_diff spec: func_800CEF74 -> func_800CEF74.func_800CEF74 (5BF94.c).
//! Inputs: arg0 in 0..31 (the edges 0, 1, 15, 16, 30, 31 often), a D_800F569C
//! object whose block8Data is a valid arena pointer or random bytes, the
//! update bit in D_800F521C set or clear, and func_800CEEBC either returning 0
//! (no work) or a random c_int of either sign. The callees write the globals
//! the C reads back (D_800F5228, D_800F5318, D_800F521C) and read the sp10
//! block they are passed, so its unk18 and unk20 reach the compared state.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CEF74));

pub const classes = [_][:0]const u8{ "call-returns-zero", "bit-clear", "bit-set-run" };

/// Set by prepare: the call to func_800CEEBC returns 0 this iteration.
var no_call: bool = false;

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = if (ctx.chance(2))
        ctx.edge(c_int, &.{ 0, 1, 15, 16, 30, 31 })
    else
        ctx.range(c_int, 0, 31);

    // The C dereferences D_800F569C without a null test: it must be valid.
    const block = ctx.alloc(v.D_800F569C_t);
    if (!ctx.chance(4)) psx.put(&block.block8Data, ctx.alloc(u8));
    v.g.D_800F569C().* = block;

    // The update bit for arg0 is set or cleared explicitly.
    const bits = v.g.D_800F521C();
    const mask = @as(u32, 1) << @as(u5, @intCast(arg0));
    if (ctx.chance(2)) bits.* |= mask else bits.* &= ~mask;

    no_call = ctx.chance(4);
    return .{arg0};
}

pub fn classify(args: Args) usize {
    if (no_call) return 0;
    const bit = (v.g.D_800F521C().* >> @as(u5, @intCast(args[0]))) & 1;
    if (bit == 0) return 1;
    return 2;
}

pub const stubs = struct {
    pub fn func_800D7890(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        // A real callee may move the counter the C increments later.
        v.g.D_800F5228().* = ctx.value(i32) >> 2;
    }

    pub fn func_800CEEBC(ctx: *zd.Ctx) c_int {
        // The C reads D_800F5318 only after this call: a real callee may change it.
        if (ctx.value(u1) == 1) v.g.D_800F5318().* = ctx.value(u8);
        if (no_call) return 0;
        return ctx.value(c_int);
    }

    pub fn func_800CE83C(ctx: *zd.Ctx, p: anytype) ?*v.D_800F53B8_t {
        // The callee reads the block the C built and may clear or set the
        // update flags the C reads back.
        const sp: *v.D_800F53B8_t2 = @ptrCast(@alignCast(p));
        v.g.D_800F5228().* = sp.unk18;
        v.g.D_800F5318().* = sp.unk20;
        if (ctx.value(u1) == 1) v.g.D_800F521C().* = ctx.value(u32);
        return null;
    }

    pub fn func_800CF478(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.D_800F5228().* = ctx.value(i32) >> 2;
    }
};
