//! Resets the battle camera, state flags and actor states (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80073718 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the battle camera and state flags, then clears or downgrades each actor's state.
pub fn func_80073718() callconv(.c) void {
    const actors = v.g.vs_battle_actors();

    v.g.D_800F196C().* = 3;
    v.g._cameraMode().* = 2;
    c.vs_battle_setStateFlag(0xAC, psx.conv(u8, v.g.vs_battle_characterState().*.?.weaponDrawn & 1));
    c.vs_battle_setStateFlag(
        0xAF,
        psx.conv(u8, @divTrunc(v.g.vs_battle_cameraCurrentSpherical().delta.pitch, 512) & 7),
    );
    if (v.g.vs_battle_cameraCurrentSpherical().initialDistance == 0x600) {
        c.vs_battle_setStateFlag(0xB0, 0);
    } else {
        c.vs_battle_setStateFlag(0xB0, 1);
    }

    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        const slot: usize = @intCast(i);
        if (actors[slot] != null) {
            _ = c.func_8009FC60(i, -2, null, -1);
            switch (@as(c_int, actors[slot].?.unk8)) {
                0x10, 0x20 => {},
                0x40 => {
                    actors[slot].?.unk8 = 0x10;
                },
                else => {
                    if (@as(c_int, actors[slot].?.unk8) == 0x80) {
                        c.func_800E6700(i);
                    }
                    actors[slot].?.unk8 = 0;
                },
            }
        }
    }

    c.func_80095B70(1);
    v.g.D_800F1858().* = 0;
    c.func_8008D594(1);
}
