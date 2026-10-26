//! The battle's per-frame wait on a target (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80078248 (src/BATTLE/BATTLE.PRG/146C.c)
/// Counts the frames a target is held and closes the wait after 31 of them, or once the chosen target is found.
pub fn func_80078248() callconv(.c) void {
    const state = v.g.D_800F19CC().*.?;
    if (state.unk2984 != 0) {
        if (state.unk8.unk4.unk0.targetActor != 0) {
            state.unk298E +%= 1;
            if (state.unk298E >= 0x1F) {
                c.func_80070F28(1);
            }
        } else if (c.func_800C58F8(&state.unk298D) != 0) {
            state.unk298C = state.unk298D;
            c.func_80070F28(1);
        }
    } else {
        c.func_80070F28(1);
    }
}
