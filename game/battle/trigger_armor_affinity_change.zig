//! Armor affinity drift when an action hits: raises the affinity the action's
//! element targets and lowers the opposing affinities (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _triggerArmorAffinityChange (src/BATTLE/BATTLE.PRG/146C.c)
/// Raises the equipment's affinity for the action's element with a chance, and lowers the opposing affinities.
pub fn triggerArmorAffinityChange(action: ?*v.vs_action_t, equipment: ?*v.vs_battle_uiEquipment, affinity: c_int, arg3: c_int, actorId: c_int) callconv(.c) void {
    const act = action.?;
    const eq = equipment.?;

    var element: c_int = affinity;
    const hit = &act.hitParams[0];
    if (psx.getBits(hit, "affinity") != 0) {
        element = @as(c_int, psx.getBits(hit, "affinity")) -% 1;
    }

    // Uninitialised in the original when `element` is outside 0..6; 0 here.
    var targetAffinity: c_int = 0;
    var physical: c_int = 0;
    var opposingAffinity: c_int = 0;

    switch (element) {
        0 => {
            targetAffinity = 0;
        },
        1 => {
            targetAffinity = 3;
            physical = 0;
            opposingAffinity = 1;
        },
        2 => {
            targetAffinity = 4;
            physical = 0;
            opposingAffinity = 2;
        },
        3 => {
            targetAffinity = 1;
            physical = 0;
            opposingAffinity = 3;
        },
        4 => {
            targetAffinity = 2;
            physical = 0;
            opposingAffinity = 4;
        },
        5 => {
            targetAffinity = 6;
            physical = 0;
            opposingAffinity = 5;
        },
        6 => {
            targetAffinity = 5;
            physical = 0;
            opposingAffinity = 6;
        },
        else => {},
    }

    // targetAffinity is 0..6 here (the switch above), so the index is in range.
    const tIdx: usize = @intCast(targetAffinity);
    if (@as(c_int, eq.affinities[tIdx]) >= 100) return;

    var roll = c.vs_main_getRand(256);

    if ((70 -% @divTrunc(@as(c_int, eq.affinities[tIdx]) + 100, 4)) >= roll) {
        eq.affinities[tIdx] +%= 1;

        if (actorId == 0) {
            c.func_80096768(arg3, targetAffinity +% 6, 1);
        }

        if (targetAffinity == 0) {
            var i: c_int = 1;
            while (i < 7) : (i +%= 1) {
                const iIdx: usize = @intCast(i);
                const ai = @as(c_int, eq.affinities[iIdx]);
                if (ai > -100) {
                    const draw = c.vs_main_getRand(256);
                    if ((@divTrunc(ai + 100, 4) + 20) >= draw) {
                        eq.affinities[iIdx] -%= 1;
                        if (actorId == 0) {
                            c.func_80096768(arg3, i +% 6, @as(c_int, @bitCast(@as(c_uint, 0x80000001))));
                        }
                    }
                }
            }
            return;
        }

        const pIdx: usize = @intCast(physical);
        if (@as(c_int, eq.affinities[pIdx]) > -100) {
            roll = c.vs_main_getRand(256);
            if ((@divTrunc(@as(c_int, eq.affinities[pIdx]) + 100, 4) + 20) >= roll) {
                eq.affinities[pIdx] -%= 1;
                if (actorId == 0) {
                    c.func_80096768(arg3, physical +% 6, @as(c_int, @bitCast(@as(c_uint, 0x80000001))));
                }
            }
        }

        const oIdx: usize = @intCast(opposingAffinity);
        if (@as(c_int, eq.affinities[oIdx]) > -100) {
            roll = c.vs_main_getRand(256);
            if ((@divTrunc(@as(c_int, eq.affinities[oIdx]) + 100, 4) + 0x14) >= roll) {
                eq.affinities[oIdx] -%= 1;
                if (actorId == 0) {
                    c.func_80096768(arg3, opposingAffinity +% 6, @as(c_int, @bitCast(@as(c_uint, 0x80000001))));
                }
            }
        }
    }
}
