//! The packet cursor and the ordering table (vs_scratch, pc/src/game/include/scratch.h), for natives whose module
//! has no view of it: unk0 is where the next packet is built, unk4 the ordering table's base, unk8 and unkC the
//! tables the menus link into. Real pointers, in a global defined in 146C.c.
pub const Scratch = extern struct {
    unk0: ?*anyopaque,
    unk4: ?*anyopaque,
    unk8: ?*anyopaque,
    unkC: ?*anyopaque,
};

extern var vs_scratch: Scratch;

pub inline fn get() *Scratch {
    return &vs_scratch;
}
