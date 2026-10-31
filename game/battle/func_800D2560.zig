//! Per-frame battle timer and camera block update: advances the timed
//! state machine, clears the block when idle, and refreshes it
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D2560 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Advances the battle's timed state, then clears or updates the camera block and refreshes it.
pub fn func_800D2560() callconv(.c) void {
    // Captured before any call: the refresh at the end uses this value, not a re-read.
    const temp_s0 = v.g.D_800F55E8().* != 0;

    if (v.g.D_800F55A0().* != 0) {
        switch (v.g.D_800F55E8().*) {
            0 => {},
            1 => c.func_800D21C0(),
            2 => c.func_800D236C(),
            3 => c.func_800D2518(),
            else => {},
        }
        if (v.g.D_800F54D0().* <= v.g.D_800F55A0().*) {
            v.g.D_800F54D0().* +%= 1;
            if (v.g.D_800F54D0().* > v.g.D_800F55A0().*) {
                v.g.D_800F54D0().* = 0;
                v.g.D_800F55A0().* = 0;
                c.func_800D1E20(0);
            }
        }
    }

    const state = v.g.D_800F54D8();
    if (v.g.D_800F5518().* != 0) {
        c.func_800D206C();
    } else {
        state.unk2C = 0;
        state.unk28 = 0;
        state.unk24 = 0;
        state.unk20 = 0;
    }

    // D_800F5518 is read again here: the branch above may have changed it.
    if (v.g.D_800F5518().* != 0 or temp_s0) {
        c.func_800D1B80(psx.cptr(c.D_800F54D8_t, state));
    }
}
