//! The battle camera's stick, d-pad and angle input (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006E7F0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Reads the camera input and steers the camera by the stick, the d-pad or the buttons.
pub fn func_8006E7F0() callconv(.c) c_int {
    var unksp10: v.func_800A1108_t = undefined;
    _ = c.func_800A1108(0, &unksp10);
    c.func_80074B14(0, @ptrCast(&unksp10));
    const temp_s0 = psx.get(v.g.vs_battle_characterState().*.?.stats);
    const temp_s1: c_uint = c.func_800A0BE0(0);

    const step = v.g.vs_battle_screenTransitionStep().*;
    if ((step -% 1) < 2 or step == 4) {
        if (psx.getBits(v.g.D_800F1AB0(), "unk6_15") != 0) {
            c.func_800B64A8(
                0,
                @as(c_int, psx.getBits(v.g.D_800F1AB0(), "unk4_13")) << 10,
                @divTrunc(@as(c_int, temp_s0.?.unk31) *% 4096, 2),
            );
        } else {
            c.func_800B64A8(0, 0, 0);
        }
    } else {
        c.func_8006E158();

        const pad = v.g.D_800F1A50();
        pad[3] = 0;
        pad[1] = 0;

        if (v.g._portInfo()[0].mode == 7) {
            const port = &v.g._portInfo()[0];
            var temp_a1: c_int = @as(c_int, port.rStickX) -% 128;
            var temp_a0: c_int = @as(c_int, port.rStickY) -% 128;

            if (psx.conv(c_uint, @as(c_int, port.rStickX) -% 64) > 128 or temp_a0 < -64 or temp_a0 > 64) {
                if (temp_a1 > 64) {
                    temp_a1 -%= 64;
                } else if (temp_a1 < -64) {
                    temp_a1 +%= 64;
                } else {
                    temp_a1 = 0;
                }

                if (temp_a0 > 64) {
                    temp_a0 -%= 64;
                } else if (temp_a0 < -64) {
                    temp_a0 +%= 64;
                } else {
                    temp_a0 = 0;
                }
                pad[3] = 0;
                pad[1] = 0 -% temp_a1;
                pad[3] = temp_a0;
            }
        }

        if (pad[1] == 0 and pad[3] == 0) {
            if ((v.g.vs_main_buttonsPreviousState().* & (1 << 14)) != 0) {
                pad[1] = 0;
                pad[3] = 16;
            }
            if ((v.g.vs_main_buttonsPreviousState().* & (1 << 12)) != 0) {
                pad[1] +%= 0;
                pad[3] -%= 16;
            }
            if ((v.g.vs_main_buttonsPreviousState().* & (1 << 15)) != 0) {
                pad[3] +%= 0;
                pad[1] +%= 16;
            }
            if ((v.g.vs_main_buttonsPreviousState().* & (1 << 13)) != 0) {
                pad[3] +%= 0;
                pad[1] -%= 16;
            }
        }

        const cam = v.g.vs_battle_cameraCurrentSpherical();
        if (cam.values.distance > 2304) {
            cam.values.distance = 2304;
        } else if (cam.values.distance < 1536) {
            cam.values.distance = 1536;
        }

        if (pad[1] != 0 or pad[3] != 0) {
            // ratan2 is called once on every path of this block, with the same arguments.
            const angle: c_int = (c.ratan2(pad[1], pad[3]) +% cam.values.yaw +% 2048) & 0xFFF;
            if ((temp_s1 & 0x80000) != 0) {
                c.func_800B64A8(0, angle, @as(c_int, temp_s0.?.unk31) *% 4096);
            } else if ((v.g.vs_main_buttonsPreviousState().* & (1 << 1)) != 0) {
                if ((v.g.vs_main_buttonsPressed().all & (1 << 7)) != 0) {
                    c.func_800A48CC(0, angle, @as(c_int, temp_s0.?.unk31) *% 4096);
                } else {
                    c.func_800B64A8(0, angle, @as(c_int, temp_s0.?.unk31) *% 4096);
                }
            } else if ((v.g.vs_main_buttonsPressed().all & (1 << 7)) != 0) {
                c.func_800A48CC(0, angle, @as(c_int, temp_s0.?.unk33) *% 4096);
            } else {
                c.func_800B64A8(0, angle, @as(c_int, temp_s0.?.unk33) *% 4096);
            }
        } else if ((temp_s1 & 0x80000) == 0 and (v.g.vs_main_buttonsPressed().all & (1 << 7)) != 0) {
            c.func_800A48CC(0, (c.ratan2(0, 0) +% cam.values.yaw +% 2048) & 0xFFF, 0);
        } else {
            c.func_800B64A8(0, c.ratan2(0, 0) & 0xFFF, 0);
        }
    }

    return 0;
}
