//! Walks the battle's linked list of entries, running each entry's state step and returning the OR of their flags (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CED60 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Steps every list entry by its state and returns the OR of their flag bits.
pub fn func_800CED60() callconv(.c) c_int {
    var s1: ?*v.D_800F53B8_t = v.g.D_800F54B0().*;
    var s3: c_int = 0;

    while (s1 != null) {
        const node = s1.?;
        v.g.D_800F53BC().* = node;
        const next = psx.get(node.next);

        switch (@as(c_int, node.unkD1C.unk3A)) {
            2 => {},
            3 => {
                c.func_800D2698(0xFF);
                c.func_800CF484(4, @ptrCast(node));
            },
            4 => {
                if (psx.get(v.g.D_800F569C().*.?.curveBlock) != null) {
                    c.func_800D1104(@as(c_int, psx.getBits(node, "unk14_16")));
                }

                c.func_800D78F0();

                var s0: ?*align(4) v.func_800D4910_t = psx.get(node.unkD1C.unk34);
                while (s0 != null) {
                    const entry = s0.?;
                    const next_entry = entry.next;
                    const Renderer = *const fn (*align(4) v.func_800D4910_t, c_int, c_int) callconv(.c) c_int;
                    const render: Renderer = @ptrCast(entry.renderer.?);
                    if (render(entry, 2, 0) == 0) {
                        // Entries are 16-byte heap blocks, so the alignment the C view asks of the pointer holds.
                        c.func_800CF70C(@ptrCast(node), @ptrCast(@alignCast(entry)));
                    }
                    s0 = next_entry;
                }

                if (c.func_800D51D8(@ptrCast(node)) == 0) {
                    c.func_800CF614(@ptrCast(node));
                    c.func_800D278C();
                } else {
                    psx.setBits(node, "unk14_16", psx.conv(u16, @as(c_int, psx.getBits(node, "unk14_16")) +% 1));
                }
            },
            else => {},
        }

        s3 |= @as(c_int, psx.getBits(node, "unk14_8"));
        s1 = next;
    }
    return s3;
}
