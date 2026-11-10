//! Unloading one actor (D2: 7E05C.s; oracle pc/src/actor_cleanup.c).
const ai = @import("views_71618");
const c = @import("c_actor_cleanup");
const v = @import("views_actor_cleanup");
const psx = @import("common").psx;

/// orig: func_800E7454 (pc/src/actor_cleanup.c)
/// Releases an actor node's hold on the navigation data: its bit in
/// D_800F590C, other actors' target ids, the grid record's actor slots and
/// (for nodes flagged 1 or 4) its AI state, its bit in the grid's busy mask
/// and, for types 0xAC and 0xAD, the data block at D_800F5920. Nothing
/// without a grid (D_800F58B8).
pub fn unloadActor(node: *ai.vs_battle_actor) callconv(.c) void {
    if (v.g.D_800F58B8().* == 0) return;
    const id: c_uint = @bitCast(node.id);
    if (@as(u8, @truncate(node.allegiance)) & 0x14 != 0) v.g.D_800F590C().* -%= @as(c_uint, 1) << @intCast(id & 31);
    const states = v.g.D_800F5878();
    var peer: ?*ai.vs_battle_actor = @ptrCast(@alignCast(v.g.vs_battle_actors()[0]));
    while (peer) |p| : (peer = @ptrCast(p.next)) {
        const other: *ai.vs_battle_aiState = @ptrCast(@alignCast(states[@as(c_uint, @bitCast(p.id))].?));
        if (@as(c_uint, @as(u8, @bitCast(other.target16))) == id) other.target16 = 0x10;
    }
    const grid = v.g.D_800F58BC().*.?;
    var slot: usize = 4;
    while (slot > 0) {
        slot -= 1;
        if (@intFromPtr(grid.registered[slot]) == @intFromPtr(node)) grid.registered[slot] = null;
    }
    if (@as(u8, @truncate(node.allegiance)) & 5 == 0) return;
    const state = states[id];
    c.func_800E5240(id);
    c.func_800E678C(state);
    if (id == 0) return;
    const bit = (@as(c_uint, 1) << @intCast(id & 31)) & grid.unk10;
    if (bit != 0) {
        grid.unk10 = @truncate(@as(c_uint, grid.unk10) -% bit);
        grid.unk12 -%= 1;
    }
    node.unkB &= 0xfc;
    if (state != null) {
        c.func_800D821C(state);
        c.func_800DBF00(state);
        c.vs_main_freeHeap(state);
        states[id] = null;
    }
    const kind = node.subType;
    if (kind == 0xac or kind == 0xad) {
        const data: ?*anyopaque = @ptrFromInt(@as(usize, v.g.D_800F5920().*));
        v.g.D_800F5920().* = 0;
        c.vs_main_freeHeap(data);
    }
}
