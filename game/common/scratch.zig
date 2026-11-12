//! The packet cursor and the ordering table (vs_scratch, pc/src/game/include/scratch.h), for natives whose module
//! has no view of it: unk0 is where the next packet is built, unk4 the ordering table's base, unk8 and unkC the
//! tables the menus link into. Real pointers, in a global defined in 146C.c.
pub const Scratch = extern struct {
    unk0: ?*anyopaque,
    unk4: ?*anyopaque,
    unk8: ?*anyopaque,
    unkC: ?*anyopaque,
};

const psx = @import("psx.zig");

/// (Through psx.Global: an `extern var` is reached by a .refptr stub on Windows, which the build rejects.)
const vs_scratch = psx.Global(Scratch, "vs_scratch");

pub inline fn get() *Scratch {
    return vs_scratch.ptr();
}
