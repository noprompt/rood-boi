//! Resolves the action's target list: keeps the targets that qualify, records their hits
//! (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007053C (src/BATTLE/BATTLE.PRG/146C.c)
/// Rebuilds the action's target list, keeping the qualifying targets and recording each one's hit.
pub fn func_8007053C() callconv(.c) void {
    const d = v.g.D_800F19CC().*.?;
    // uninitialised in the original: written by func_8008631C before it is read
    var result: v.D_800F19CC_t2 = std.mem.zeroes(v.D_800F19CC_t2);

    d.unk2990 = d.unk2998;
    c.func_800C06E0();
    if (d.unk2990.pad != 0) {
        c.func_800C16DC();
        c.func_800C06E0();
        c.func_800C0738();
        c.func_800C05B4();
        if (psx.getBits(psx.at(v.g.actions(), d.unk8.actionIndex), "unk2_0") == 0) {
            c.func_800CB114();
            c.func_8006FBCC(0);
            return;
        }
        c.func_800704D8();
        return;
    }

    const action: c_int = @as(c_int, d.unk8.actionIndex);
    d.unk29B8 = d.unk2990;
    c.func_800C0700(@ptrCast(&d.unk29B0));

    var kept: c_int = 0;
    var i: c_int = 0;
    while (i < @as(c_int, d.unk2C00)) : (i +%= 1) {
        if (v.g.D_800E81C4()[psx.getBits(psx.at(v.g.actions(), action), "unk2_4")] != 0) {
            if (c.func_800C1564(@ptrCast(&d.unk29B0), @ptrCast(psx.at(&d.unk29C0, i))) != 0) {
                c.vs_main_memcpy(@ptrCast(psx.at(&d.unk29C0, kept)), @ptrCast(psx.at(&d.unk29C0, i)), 24);
                _ = c.func_8008631C(
                    action,
                    @as(c_int, d.unk8.unk4.unk0.targetActor),
                    @as(c_int, psx.at(&d.unk29C0, kept).unk9),
                    @as(c_int, psx.conv(i8, psx.at(&d.unk29C0, kept).unkA)),
                    &result,
                );
                c.func_8006F630(@ptrCast(psx.at(&d.unk29C0, kept)), @ptrCast(&result), @ptrCast(&result.unk4C[0]));
                kept +%= 1;
            }
        } else if (c.func_800C1564(@ptrCast(&d.unk29B0), @ptrCast(psx.at(&d.unk29C0, i))) != 0) {
            psx.at(&d.unk29C0, kept).unk8 = 16;
            const av: *v.actionTargetContextView = @ptrCast(d);
            psx.at(&av.targets, kept).limb = -1;
            psx.at(&d.unk29C0, kept).unk9 = psx.at(&d.unk29C0, i).unk9;
            psx.at(&d.unk29C0, kept).unk0 = psx.at(&d.unk29C0, i).unk0;
            const slot: u8 = psx.at(&d.unk29C0, kept).unk9;
            const stats = psx.get(v.g.vs_battle_actors()[slot].?.stats).?;
            _ = c.func_8008631C(
                action,
                @as(c_int, d.unk8.unk4.unk0.targetActor),
                @as(c_int, slot),
                @as(c_int, psx.getBits(stats, "unk36")),
                &result,
            );
            c.func_8006F630(@ptrCast(psx.at(&d.unk29C0, kept)), @ptrCast(&result), @ptrCast(&result.unk4C[0]));
            kept +%= 1;
        }
    }

    d.unk2C00 = psx.conv(u16, kept);
    c.func_800C1664(kept, psx.conv(c_int, psx.addr(&d.unk29C0[0])), 1);
    v.g._cameraMode().* = 3;
}
