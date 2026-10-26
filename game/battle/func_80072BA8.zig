//! Battle action setup: the action's display routine, or the party layout for action 0 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80072BA8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets up battle action `action`: action 0 lays out the party rows and limb list, other actions pick their display routine.
pub fn func_80072BA8(action: c_int) callconv(.c) void {
    v.g.D_800F19CC().*.?.unk8.actionIndex = psx.conv(u16, action);
    _ = c.func_800C16DC();
    _ = c.func_800C06E0();
    _ = c.func_800C0738();

    if (action == 0) {
        var state: v.func_8006EBF8_t = undefined;

        v.g.D_800F19CC().*.?.unk29A0 = 1;
        v.g.D_800F19CC().*.?.unk29A1 = 3;
        _ = c.func_800A1108(0, @ptrCast(&state));
        v.g.D_800F19CC().*.?.unk29A2 = state.unk0.unk4.pad;
        v.g.D_800F19CC().*.?.unk29A4 = 4;
        v.g.D_800F19CC().*.?.unk29A5 = 4;
        v.g.D_800F19CC().*.?.unk29A6 = 4;
        v.g.D_800F19CC().*.?.unk29A7 = 0;
        _ = c.func_800A190C(0, 250, @ptrCast(&v.g.D_800F19CC().*.?.unk29A8), 0);
        _ = c.func_800C05EC(@ptrCast(&v.g.D_800F19CC().*.?.unk29A0), null, 0, 0);

        v.g.D_800F19CC().*.?.unk29B0 = 2;
        v.g.D_800F19CC().*.?.unk29B1 = 3;
        _ = c.func_800A1108(1, @ptrCast(&state));
        v.g.D_800F19CC().*.?.unk29B2 = state.unk0.unk4.pad;
        v.g.D_800F19CC().*.?.unk29B4 = 4;
        v.g.D_800F19CC().*.?.unk29B5 = 4;
        v.g.D_800F19CC().*.?.unk29B6 = 4;
        v.g.D_800F19CC().*.?.unk29B7 = 0;
        _ = c.func_800A190C(1, 250, @ptrCast(&v.g.D_800F19CC().*.?.unk29B8), 0);
        c.func_800C0700(@ptrCast(&v.g.D_800F19CC().*.?.unk29B0));

        var limb: c_int = 0;
        var count: c_int = 0;
        while (limb < 6) : (limb +%= 1) {
            const part = c.func_800A152C(1, limb, 2);
            if (part >= 0) {
                // count <= limb < 6: below the 23 slots of unk29C0.
                const slot: usize = @intCast(count);
                const el = &v.g.D_800F19CC().*.?.unk29C0[slot];
                _ = c.func_800A1B9C(1, limb, @ptrCast(el), 0);
                el.unk8 = psx.conv(u8, c.func_800A1648(1, part, 0));
                el.unkA = psx.conv(u8, limb);
                el.unk9 = 1;
                count +%= 1;
            }
        }
        v.g.D_800F19CC().*.?.unk2C00 = psx.conv(u16, count);
        c.func_800C1664(count, psx.conv(c_int, psx.addr(&v.g.D_800F19CC().*.?.unk29C0[0])), 0);
        v.g._cameraMode().* = 1;
        return;
    }

    // The action header is the first byte-aligned flags byte of vs_main_actions[action] (no bounds check, as the C).
    const header = psx.byteAt(v.actionHeaderView, psx.at(v.g.actions(), action), 0);
    const category: u8 = header.flags >> 4;
    if (v.g.D_800E8184()[category] != 0) {
        if (v.g.D_800E8194()[category] != 0) {
            if (v.g.D_800E81C4()[category] == 0) {
                _ = c.func_80072734(0);
            } else {
                _ = c.func_80072734(1);
            }
        } else if (v.g.D_800E81C4()[category] == 0) {
            _ = c.func_80071F68(2);
        } else {
            _ = c.func_80071F68(3);
        }
    } else if (v.g.D_800E8194()[category] != 0) {
        _ = c.func_800719FC(4);
    } else {
        c.func_800719DC(6);
    }
}
