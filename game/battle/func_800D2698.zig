//! Builds the battle node chain: `count` linked nodes in a doubly-linked list (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D2698 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Allocates `count` linked nodes into the global chain; later calls only count up.
pub fn func_800D2698(count: c_int) callconv(.c) void {
    if (v.g.D_800F5600().* != 0) {
        v.g.D_800F5600().* +%= 1;
        return;
    }

    // sizeof * count is computed in size_t and truncated to the u_int argument: the low 32 bits are the same on every target.
    const bytes: c_uint = @as(c_uint, @sizeOf(v.func_800D2904_t)) *% psx.conv(c_uint, count);
    const raw = c.vs_main_allocHeapR(bytes);
    v.g.D_800F55FC().* = @ptrCast(@alignCast(raw));
    const nodes = v.g.D_800F55FC().*.?;

    psx.put(&nodes.previous, null);
    psx.put(&nodes.next, psx.at(nodes, 1));

    var i: c_int = 1;
    while (i < count -% 1) : (i +%= 1) {
        psx.put(&psx.at(nodes, i).previous, psx.at(nodes, i -% 1));
        psx.put(&psx.at(nodes, i).next, psx.at(nodes, i +% 1));
    }

    v.g.D_800F55F8().* = 0;
    v.g.D_800F55F0().* = count;
    v.g.D_800F5600().* = 1;
    psx.put(&psx.at(nodes, i).previous, psx.at(nodes, i -% 1));
    psx.put(&psx.at(nodes, i).next, null);
    v.g.D_800F55F4().* = v.g.D_800F55FC().*;
}
