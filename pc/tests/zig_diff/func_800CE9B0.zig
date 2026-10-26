//! zig_diff spec: func_800CE9B0 -> func_800CE9B0.func_800CE9B0 (5BF94.c).
//! Inputs: the state machine's global D_800F531C picked from every case, the
//! default (1, 5, 7 and high-bit values), and the globals each case reads: the
//! D_800F569C block (valid whenever the C dereferences it, states 3 and 4; null
//! or valid otherwise), its curve, block9, block12 and block13 pointers (null
//! and non-null), the CD slot (null, or a state from 4/0/3/-1/5), the D_800F53B8
//! node list (0 to 3 nodes, with unk14_16 at 0, 1 and 0xFFFF), the loop bounds
//! D_800F5224/D_800F5228 (equal and signed negative values), and the effect
//! and load-context fields (zero, one, sign bit set). The CD allocator stub
//! records the request it is passed in the slot it returns, so a wrong file
//! size in the C shows up in the state. The callees that return values the C
//! tests (the purge, the 2/8/3 waits, the block-7 loader, the func_800D51D8
//! check, the CD allocator) return zero and nonzero. The state-setting callee
//! func_800CF478 writes D_800F531C, and func_800D78F0 may clear the list head
//! the C reads after its loop.
//!
//! Coverage notes for the checker (ids are as zig_diff.py prints them):
//! - +80 b0 (func_800D51D8 == 0): the zero result sends the C to
//!   func_800CE8F4, a unit static that c_5BF94 cannot call (calling it traps),
//!   so the spec keeps the result nonzero. Waived.
//! - +132 b3 (`D_800F569C || var_s2` in case 9): var_s2 is set to 1 at the
//!   start of the function and nothing before this test in case 9 writes it,
//!   so the false edge of the var_s2 test cannot be taken. Waived.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CE9B0));

pub const classes = [_][:0]const u8{
    "state0",
    "state2",
    "state3",
    "state4-loop",
    "state4-done",
    "state6",
    "state8",
    "state9-slot",
    "state9-idle",
    "other",
};

pub const stubs = struct {
    pub fn vs_battle_loadEffPurge(ctx: *zd.Ctx) c_int {
        return if (ctx.value(u8) < 128) 0 else 1;
    }

    pub fn func_800D7CFC(ctx: *zd.Ctx) c_int {
        return if (ctx.value(u8) < 128) 0 else 1;
    }

    pub fn func_800D7EF4(ctx: *zd.Ctx) c_int {
        return if (ctx.value(u8) < 128) 0 else 1;
    }

    pub fn func_800D7BF8(ctx: *zd.Ctx) c_int {
        return if (ctx.value(u8) < 128) 0 else 1;
    }

    // Always nonzero: a zero result calls the unit static func_800CE8F4 (see the header).
    pub fn func_800D51D8(ctx: *zd.Ctx, node: anytype) c_int {
        if (ctx.value(u1) == 1) {
            const raw: ?*anyopaque = @ptrCast(node);
            const n: *v.D_800F53B8_t = @ptrCast(@alignCast(raw.?));
            psx.setBits(n, "unk14_16", ctx.value(u16));
        }
        return 1;
    }

    // May clear the list head the C reads after its loop.
    pub fn func_800D78F0(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 64) v.g.D_800F53B8().* = null;
    }

    // The callee moves the state machine: model the store.
    pub fn func_800CF478(ctx: *zd.Ctx, arg: anytype) void {
        _ = ctx;
        v.g.D_800F531C().* = @intCast(arg);
    }

    // Records the request (lba and size) in the slot it hands back, so the
    // size the C passes reaches the compared state.
    pub fn vs_main_allocateCdQueueSlot(ctx: *zd.Ctx, p: anytype) ?*v.vs_main_CdQueueSlot {
        const req: *const v.vs_main_CdFile = @ptrCast(@alignCast(p));
        if (ctx.value(u8) < 32) return null;
        const s = ctx.alloc(v.vs_main_CdQueueSlot);
        s.state = ctx.value(i16);
        s.cdFile = req.*;
        return s;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const state = ctx.edge(u32, &.{ 0, 6, 2, 8, 3, 4, 9, 1, 5, 7, 0x8000_0003, 0xFFFF_FFFF });
    v.g.D_800F531C().* = state;

    // The C dereferences the block in states 3 and 4 only.
    const block = ctx.alloc(v.D_800F569C_t);
    if (state == 3 or state == 4 or ctx.chance(3)) {
        v.g.D_800F569C().* = block;
    } else {
        v.g.D_800F569C().* = null;
    }

    const none_cb: ?*v.pFileCurveBlock = null;
    psx.put(&block.curveBlock, if (ctx.chance(2)) none_cb else ctx.alloc(v.pFileCurveBlock));

    const b9 = ctx.alloc(v.pFileBlock9);
    b9.unk14 = ctx.edge(u8, &.{ 0, 1, 2, 8, 30 });
    psx.put(&block.block9Data, b9);

    const none_v: ?*anyopaque = null;
    const p12: ?*anyopaque = @ptrCast(ctx.allocBytes(16, 16));
    psx.put(&block.block12Data, if (ctx.chance(2)) none_v else p12);
    const p13: ?*anyopaque = @ptrCast(ctx.allocBytes(16, 16));
    psx.put(&block.block13Data, if (ctx.chance(2)) none_v else p13);

    // The node list the C walks in state 4.
    var head: ?*v.D_800F53B8_t = null;
    const n = ctx.range(u8, 0, 3);
    var i: u8 = 0;
    while (i < n) : (i += 1) {
        const node = ctx.alloc(v.D_800F53B8_t);
        psx.put(&node.next, head);
        psx.setBits(node, "unk14_16", ctx.pick(u16, &.{ 0, 1, 0xFFFF }));
        head = node;
    }
    v.g.D_800F53B8().* = head;

    v.g.D_800F5224().* = ctx.edge(i32, &.{ -1, 0, 1, 2, 3 });
    v.g.D_800F5228().* = ctx.edge(i32, &.{ -1, 0, 1, 2, 3 });
    v.g.D_800F5684().* = ctx.edge(i32, &.{ 0, 1, -2147483648, 0x7FFF_FFFF });
    v.g.D_800F5230().effectId = ctx.edge(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    v.g.vs_battle_pFileLoadContext().lba = ctx.edge(u16, &.{ 0, 1, 0x8000 });

    if (ctx.chance(2)) {
        v.g.D_800F5218().* = null;
    } else {
        const slot = ctx.alloc(v.vs_main_CdQueueSlot);
        slot.state = ctx.edge(i16, &.{ 4, 0, 3, -1, 5 });
        v.g.D_800F5218().* = slot;
    }

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const state = v.g.D_800F531C().*;
    return switch (state) {
        0 => 0,
        2 => 1,
        3 => 2,
        4 => if (v.g.D_800F53B8().* != null) 3 else 4,
        6 => 5,
        8 => 6,
        9 => if (v.g.D_800F5218().* != null) 7 else 8,
        else => 9,
    };
}
