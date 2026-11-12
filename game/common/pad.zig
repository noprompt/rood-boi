//! The scratchpad's remaining bytes (vs_pad, pc/src/game/include/scratch.h): the PS1 kept the per-file scratch
//! views, the actor transform and AI slots, and the collision and GTE work areas in its 1 KB scratchpad at
//! 0x1F800000. They overlay one another (a view of one file is another's at a different time), so they stay one
//! block, indexed by their PS1 offset from 0x1F800000. The bytes below 0x68 are the packet cursor and the view
//! (vs_scratch, vs_view): named globals, not here.
const psx = @import("psx.zig");

/// Hidden, so Windows reaches it directly rather than through a .refptr stub (the build rejects those); not
/// psx.Global: file-scope views (`pad.ptr` in a `const`) need its address at compile time.
const vs_pad: *align(16) [0x400]u8 = if (psx.library or psx.host)
    @extern(*align(16) [0x400]u8, .{ .name = "vs_pad" }) // (through the GOT, as psx.Global does there)
else
    @extern(*align(16) [0x400]u8, .{ .name = "vs_pad", .visibility = .hidden });

/// The address of the byte at `offset` (a PS1 offset from 0x1F800000, 0x68..0x3FF).
pub inline fn addr(offset: usize) usize {
    return @intFromPtr(vs_pad) + offset;
}

/// The same as a 32-bit guest address, for the words the game keeps its own addresses in (the image is linked
/// below 4 GB, as every global is).
pub inline fn guest(offset: usize) u32 {
    return @intCast(addr(offset));
}

/// A typed view of the bytes at `offset`, for a file-scope view of a scratch area.
pub inline fn ptr(comptime T: type, comptime offset: usize) *T {
    return @ptrCast(@alignCast(&vs_pad[offset]));
}
