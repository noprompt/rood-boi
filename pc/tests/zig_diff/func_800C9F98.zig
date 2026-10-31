//! zig_diff spec: func_800C9F98 -> func_800C9F98.func_800C9F98 (5BF94.c).
//! Inputs: the two int arguments, each an edge (0, -1, 1, INT_MAX, INT_MIN)
//! half the time and any value otherwise. vs_scratch.unk8 and unk4 hold valid
//! arena blocks (the C dereferences unk8 through psx_get and writes the
//! returned prim), so the C never faults. The callee is a recording stub: it
//! returns a fresh 32-byte arena block, writes some of its words, and
//! sometimes repoints vs_scratch.unk8, which the C does not read back.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C9F98));

pub const classes = [_][:0]const u8{ "zero-arg0", "negative-arg0", "positive-arg0" };

pub const stubs = struct {
    pub fn vs_battle_setSpriteDefaultTexPage(ctx: *zd.Ctx, brightnessTransparency: anytype, xy: anytype, wh: anytype, nextPrim: anytype) [*c]c.u_long {
        _ = brightnessTransparency;
        _ = xy;
        _ = wh;
        _ = nextPrim;
        // The prim the callee returns: a valid block the C writes words 1 and 4 of.
        const block: [*c]c.u_long = @ptrCast(@alignCast(ctx.allocBytes(32, 16)));
        block[0] = ctx.value(c.u_long);
        block[2] = ctx.value(c.u_long);
        block[3] = ctx.value(c.u_long);
        // The callee may repoint the scratch's unk8 (the C reads it only before the call).
        if (ctx.value(u1) == 1) psx.put(&v.g.vs_scratch().unk8, block);
        return block;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const scratch = v.g.vs_scratch();
    const primA = ctx.allocBytes(32, 16);
    const primB = ctx.allocBytes(32, 16);
    psx.put(&scratch.unk8, primA);
    psx.put(&scratch.unk4, primB);
    const edges = [_]c_int{ 0, -1, 1, 0x7FFF_FFFF, -0x8000_0000 };
    const a = ctx.pick(c_int, &edges);
    const b = ctx.pick(c_int, &edges);
    return .{ a, b };
}

pub fn classify(args: Args) usize {
    const a = args[0];
    if (a == 0) return 0;
    if (a < 0) return 1;
    return 2;
}
