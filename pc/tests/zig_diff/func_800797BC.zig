//! zig_diff spec: func_800797BC -> func_800797BC.func_800797BC (146C.c).
//! Inputs: none (the function takes no arguments). func_800CB66C returns a
//! block in the arena (the C dereferences it, so it is always valid) whose
//! unk0 is 1, 0 or 0x102 at prepare. func_800C97BC may rewrite unk0 (to 1 or
//! to any 32-bit value) before the read, so the test sees both outcomes, and
//! the port must read unk0 after that call, not before it.
const std = @import("std");
const zd = @import("zdiff");
const c = @import("c_146C");

/// The block func_800CB66C returns: unk0 at offset 0 (the C's own width is
/// narrower or equal, so every byte it reads is one the harness set).
const Blk = extern struct {
    unk0: u32,
};

/// Set by prepare, returned by the func_800CB66C stub.
var blk: *Blk = undefined;

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800797BC));

pub const classes = [_][:0]const u8{ "unk0-is-1", "unk0-not-1" };

pub const stubs = struct {
    /// Rewrites the block the C reads back after this call: 1 or any value.
    pub fn func_800C97BC(ctx: *zd.Ctx) void {
        blk.unk0 = if (ctx.value(u1) == 1) 1 else ctx.value(u32);
    }

    /// Always a valid block: the C dereferences the result without a test.
    pub fn func_800CB66C(ctx: *zd.Ctx) ?*c.D_800F18EC_t {
        _ = ctx;
        return @ptrCast(blk);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    blk = ctx.alloc(Blk);
    blk.unk0 = ctx.pick(u32, &.{ 1, 0, 0x102 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (blk.unk0 == 1) 0 else 1;
}
