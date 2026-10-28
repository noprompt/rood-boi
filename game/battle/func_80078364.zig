//! The battle action wait and finish state machine (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80078364 (src/BATTLE/BATTLE.PRG/146C.c)
/// Counts down the action wait, then runs the finish of the action (or the battle end) once the wait ends.
pub fn func_80078364() callconv(.c) void {
    if (v.g.D_800F19CC().*.?.unk2984 != 0) {
        if (v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor != 0) {
            v.g.D_800F19CC().*.?.unk298E +%= 1;
            if (@as(c_int, v.g.D_800F19CC().*.?.unk298E) >= 0x1F) {
                v.g.D_800F19CC().*.?.unk298C = 0;
                c.func_80070F28(2);
            }
        } else if (c.func_800C58F8(&v.g.D_800F19CC().*.?.unk298D) != 0) {
            v.g.D_800F19CC().*.?.unk298C = v.g.D_800F19CC().*.?.unk298D;
            if (@as(c_int, v.g.D_800F19CC().*.?.unk298C) == 0xFF) {
                const action = psx.at(v.g.actions(), v.g.D_800F19CC().*.?.unk8.actionIndex);
                if (v.g.D_800E8184()[psx.getBits(action, "unk2_4")] != 0) {
                    c.func_80072BA8(@as(c_int, v.g.D_800F19CC().*.?.unk8.actionIndex));
                    return;
                }
                c.func_800C16DC();
                c.func_800C06E0();
                c.func_800C0738();
                c.func_800C05B4();
                c.func_800704D8();
                return;
            }
            c.func_80070F28(2);
        }
    } else {
        v.g.D_800F19CC().*.?.unk298C = 0;
        c.func_80070F28(2);
    }
}
