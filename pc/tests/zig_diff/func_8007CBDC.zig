//! zig_diff spec: func_8007CBDC -> func_8007CBDC.func_8007CBDC (146C.c).
//! Inputs: any c_int for index, wepId and arg2, drawn from the edges that
//! matter for the narrowing into objData's fields (i8 index, i16 modelId,
//! u8 unk11): 0, -1, 127/128, 255/256, 32767/32768, 65535/65536, and the
//! int extremes, plus random values. The populate call is a recording stub:
//! it copies the fields the C sets (dataType, index, modelId, actorId, unk11)
//! into an arena record the harness compares, so a wrong stored value shows
//! up as a state mismatch. It also writes the fields the real callee fills in
//! (dataAddr, material, variant) with ctx.value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CBDC));

pub const classes = [_][:0]const u8{ "negative-index", "non-negative-index" };

/// The arena record the populate stub copies the C's stored fields into.
/// Set by prepare each iteration; its bytes are compared like any state.
var seen: *v.vs_battle_objectData = undefined;

pub const stubs = struct {
    pub fn vs_battle_populateDataSlot(ctx: *zd.Ctx, p: anytype) c_int {
        const o: *v.vs_battle_objectData = @ptrCast(@alignCast(p.?));
        // Record what the caller stored in the fields the real callee reads.
        seen.dataType = o.dataType;
        seen.index = o.index;
        seen.modelId = o.modelId;
        seen.actorId = o.actorId;
        seen.unk11 = o.unk11;
        // The real callee fills these in; the C never reads them back, but
        // the state comparison does.
        if (ctx.value(u1) == 1) o.dataAddr = ctx.value(u32);
        if (ctx.value(u1) == 1) o.material = ctx.value(u8);
        if (ctx.value(u1) == 1) o.variant = ctx.value(u8);
        return ctx.value(c_int);
    }
};

const edges = [_]c_int{
    0,                      -1,                    1,     127,   128,   255,  256,
    32767,                  32768,                 -32768, 65535, 65536, -65536,
    std.math.maxInt(c_int), std.math.minInt(c_int),
};

pub fn prepare(ctx: *zd.Ctx) Args {
    seen = ctx.alloc(v.vs_battle_objectData);
    const index = ctx.pick(c_int, &edges);
    const wepId = ctx.pick(c_int, &edges);
    const arg2 = ctx.pick(c_int, &edges);
    return .{ index, wepId, arg2 };
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
