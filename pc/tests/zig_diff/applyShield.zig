//! zig_diff spec: vs_battle_applyShield -> apply_shield.applyShield (146C.c).
//! Inputs: a target that is sometimes null (the C never reads it), a source
//! that is sometimes null (the C's only guard), a random index byte (values
//! of 128 and up show the signed slip), a random material source (base.maxDp
//! differs from base.material), and three gem bytes drawn from edges: 0 (no
//! copy), 1 and 0x30 (indices 0 and 47), 0x80 (index -1, the `& 0x7F` edge),
//! 0x81 (index 0 only under 0x7F, which tells 0x7F from 0x7E), 0xB0 (index 47
//! via the mask). Stubs: the allocator hands out an arena block, bzero zeroes
//! it like the real callee, and the other callees record only (nothing the C
//! reads back changes).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyShield));

pub const classes = [_][:0]const u8{ "null-source", "no-gems", "gem-index-minus-one", "gem-in-range" };

const gem_edges = [_]u8{ 0, 1, 0x80, 0x81, 48, 0xB0 };

pub const stubs = struct {
    /// The C does not test the result and bzeros it: always a valid block.
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        return @ptrCast(ctx.allocBytes(512, 16));
    }

    /// The real callee zeroes the block.
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const bytes: [*]u8 = @ptrCast(p orelse return);
        @memset(bytes[0..@intCast(n)], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target: ?*v.vs_battle_uiShield = if (ctx.chance(8)) null else ctx.alloc(v.vs_battle_uiShield);
    if (ctx.chance(6)) return .{ target, null };

    const source = ctx.alloc(v.vs_main_inventoryShield);
    source.index = ctx.int(u8);
    source.base.material = ctx.int(u16);
    source.base.maxDp = ctx.int(u16);
    const none = ctx.chance(5);
    for (&source.gems) |*g| {
        g.* = if (none or ctx.chance(3)) 0 else ctx.edge(u8, &gem_edges);
    }
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const source = args[1] orelse return 0;
    var any = false;
    var minus = false;
    for (source.gems[0..3]) |g| {
        if (g != 0) any = true;
        if (g != 0 and (g & 0x7F) == 0) minus = true;
    }
    if (!any) return 1;
    return if (minus) 2 else 3;
}
