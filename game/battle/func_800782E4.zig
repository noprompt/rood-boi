//! The battle's per-frame wait check before its action step runs (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800782E4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Advances the wait counter while a target is set, else asks func_800C4794; runs func_8007053C once the wait is over.
pub fn func_800782E4() callconv(.c) void {
    const state = v.g.D_800F19CC().*.?;
    if (state.unk2984 != 0) {
        if (state.unk8.unk4.unk0.targetActor != 0) {
            state.unk298E +%= 1;
            const count: c_uint = state.unk298E;
            if (count < 0x1F) return;
        } else if (c.func_800C4794(psx.cptr(c.SVECTOR, &state.unk2998)) == 0) {
            return;
        }
    }
    c.func_8007053C();
}
