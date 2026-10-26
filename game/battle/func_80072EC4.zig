//! Starts a battle action: resets the action record for the target actor and clears the other actors' pending flags (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80072EC4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets up the action record for target actor `arg0` with action index `arg1` and prepares the battle for it.
pub fn func_80072EC4(arg0: c_int, arg1: c_ushort) callconv(.c) void {
    v.g.D_800F196C().* = 2;
    c.vs_main_bzero(&v.g.D_800F19CC().*.?.unk8, 0x84C);
    v.g.D_800F19CC().*.?.unk8.unk4.unk40 = 0;
    v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor = psx.conv(u8, arg0);
    v.g.D_800F19CC().*.?.unk8.actionIndex = arg1;
    c.func_8006EF10();
    c.func_80088CA0();
    if (arg0 != 0) {
        v.g.D_800F19CC().*.?.unk2984 = 0;
    } else {
        v.g.D_800F19CC().*.?.unk2984 = 1;
    }
    v.g.D_800F19CC().*.?.unk298C = 0xFF;
    v.g.D_800F19CC().*.?.unk298D = 0xFF;

    // vs_battle_actors[arg0]: no bounds check, as in the C; a null actor traps where the C would fault.
    const temp_a0: *v.vs_battle_actor = psx.at(v.g.vs_battle_actors(), arg0).*.?;
    v.g.D_800F19CC().*.?.unk29C0[0].unk9 = temp_a0.unk10.u8[0];
    v.g.D_800F19CC().*.?.unk29C0[0].unkA = temp_a0.unk10.u8[2];
    v.g.D_800F19CC().*.?.unk8.unk4A = 0;
    v.g.D_800F19CC().*.?.unk298E = 0;
    v.g.D_800F19CC().*.?.unk4 = 0;
    c.func_8009E5C4(@as(c_int, v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor));

    if (v.g.D_800F19CC().*.?.unk2984 != 0) {
        c.func_800C031C();
        c.func_8007B10C(0xD, 4, -4, -4, 0);
    }

    c.func_8006C250();

    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        if (i != @as(c_int, v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor)) {
            const temp_v0: c_uint = c.func_800A0BE0(i);
            if ((temp_v0 & 4) != 0) {
                // The flags argument is an int in the callee's prototype: the C converts the u_int.
                c.func_800A087C(i, psx.conv(c_int, temp_v0 & ~@as(c_uint, 4)));
            }
        }
    }

    if (arg0 == 0) {
        _ = c.func_8008B4C8(0);
    }
    c.func_8008B4BC(1);
    c.func_8008D594(1);
    if (v.g.D_800F19CC().*.?.unk2984 != 0) {
        c.func_80095B70(1);
    }
    c.func_80072BA8(@as(c_int, v.g.D_800F19CC().*.?.unk8.actionIndex));
    c.vs_main_setClutState(0);
}
