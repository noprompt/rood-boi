//! Battle load and scene state machine step, driven by D_800F531C (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CE9B0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Runs one step of the battle load state machine; returns 1 while it is still busy, 0 when done.
pub fn func_800CE9B0() callconv(.c) c_int {
    var var_s0: ?*v.D_800F53B8_t = v.g.D_800F53B8().*;
    var var_s2: c_int = 1;

    sw: switch (v.g.D_800F531C().*) {
        0 => {
            var_s2 = 0;
        },
        6 => {
            if (c.vs_battle_loadEffPurge() == 0) {
                c.vs_main_wait();
                c.vs_effpurge_exec();
                if (v.g.D_800F5230().effectId != 0 and v.g.vs_battle_pFileLoadContext().lba == 0) {
                    c.func_800CF478(4);
                    v.g.D_800F5224().* = 0;
                    v.g.D_800F5228().* = 0;
                } else {
                    c.func_800CF478(2);
                }
                if (v.g.D_800F5684().* != 0) {
                    _ = c.func_8007E1C0(2);
                    v.g.D_800F5684().* = 0;
                }
            }
        },
        2 => {
            if (c.func_800D7CFC() == 0) {
                c.func_800CF478(8);
            }
        },
        8 => {
            if (c.func_800D7EF4() == 0) {
                c.func_800CF478(3);
                c.vs_main_wait();
            }
        },
        3 => {
            if (c.func_800D7BF8() == 0) {
                c.func_800D8060(v.g.vs_battle_pfileBuf().*);
                c.func_800CF478(5);

                v.g.D_800F5224().* = @as(i32, psx.get(v.g.D_800F569C().*.?.block9Data).?.unk14);
                v.g.D_800F5228().* = 0;

                var i: c_int = 0;
                while (i < v.g.D_800F5224().*) : (i +%= 1) {
                    // x86 masks the shift count to 5 bits; the mask keeps the same bit.
                    const sh: u5 = @truncate(@as(c_uint, @bitCast(i)));
                    v.g.D_800F521C().* |= @as(c_uint, 1) << sh;
                }

                v.g.D_800F54A8().* = 1;
                var sp38: v.vs_main_CdFile = undefined;
                sp38.lba = c.vs_battle_getMainMenuLba();
                sp38.size = 0;
                v.g.D_800F5218().* = @ptrCast(c.vs_main_allocateCdQueueSlot(psx.cptr(c.vs_main_CdFile, &sp38)));
                c.vs_main_cdEnqueue(@ptrCast(v.g.D_800F5218().*), null);
            }
        },
        4 => {
            while (var_s0) |node| {
                const temp_s1 = psx.get(node.next);
                v.g.D_800F53BC().* = node;

                if (psx.get(v.g.D_800F569C().*.?.curveBlock) != null) {
                    c.func_800D1104(@as(c_int, psx.getBits(node, "unk14_16")));
                }

                c.func_800D78F0();

                if (c.func_800D51D8(@ptrCast(node)) == 0) {
                    _ = c.func_800CE8F4(@ptrCast(node));
                } else {
                    psx.setBits(node, "unk14_16", psx.conv(u16, @as(c_int, psx.getBits(node, "unk14_16")) +% 1));
                }

                var_s0 = temp_s1;
            }

            if (v.g.D_800F53B8().* != null) break :sw;

            if (v.g.D_800F5224().* <= v.g.D_800F5228().*) {
                if (psx.get(v.g.D_800F569C().*.?.block12Data) != null) {
                    _ = c.func_80046194();
                    psx.put(&v.g.D_800F569C().*.?.block12Data, null);
                }

                if (psx.get(v.g.D_800F569C().*.?.block13Data) != null) {
                    _ = c.func_80046634();
                    psx.put(&v.g.D_800F569C().*.?.block13Data, null);
                    v.g.D_800F569C().*.?.unkCC = 0;
                }

                _ = c.func_800434A4(0, 1);
                c.func_800D7C5C();
                c.func_800D278C();
                c.func_800CF514(@as(c_int, v.g.D_800F5318().*));

                v.g.D_800F54A8().* = 0;
                v.g.D_800F5318().* = 0;

                if (v.g.D_800F5684().* != 0) {
                    _ = c.func_8007E1C0(2);
                    v.g.D_800F5684().* = 0;
                }

                c.func_800D1930();
                c.func_800CF478(9);
            } else {
                c.func_800CF478(5);
            }

            var_s2 = 1;
        },
        9 => {
            if (v.g.D_800F5218().*) |slot| {
                if (slot.state != 4) {
                    var_s2 = 1;
                    break :sw;
                }
                c.vs_main_freeCdQueueSlot(@ptrCast(slot));
                v.g.D_800F5218().* = null;
            }
            c.func_800CF478(0);
            var_s2 = 0;
        },
        else => {},
    }

    return var_s2;
}
