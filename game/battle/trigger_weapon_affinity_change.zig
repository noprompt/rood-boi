//! Weapon affinity change: a hit raises the target affinity and may lower the opposing ones
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _triggerWeaponAffinityChange (src/BATTLE/BATTLE.PRG/146C.c)
/// Raises an equipment's affinity to the hit's element with a chance, and may lower its related affinities.
pub fn triggerWeaponAffinityChange(action: ?*v.vs_action_t, equipment: ?*v.vs_battle_uiEquipment, affinity: c_int, arg3: c_int, suppressNotification: c_int) callconv(.c) void {
    const act = action.?;
    const eq = equipment.?;
    const aff = &eq.affinities;
    const notify = suppressNotification == 0;

    var kind: c_int = affinity;
    const hitAffinity = psx.getBits(&act.hitParams[0], "affinity");
    if (hitAffinity != 0) {
        kind = @as(c_int, hitAffinity) -% 1;
    }

    // Cases 1..6 set opposingAffinity; physical is 0 in every case that reads it.
    // Outside 0..6 the C leaves targetAffinity uninitialised; 0 is used here.
    var targetAffinity: c_int = 0;
    var physical: c_int = 0;
    var opposingAffinity: c_int = 0;
    switch (kind) {
        0 => {
            targetAffinity = 0;
        },
        1 => {
            targetAffinity = 1;
            physical = 0;
            opposingAffinity = 3;
        },
        2 => {
            targetAffinity = 2;
            physical = 0;
            opposingAffinity = 4;
        },
        3 => {
            targetAffinity = 3;
            physical = 0;
            opposingAffinity = 1;
        },
        4 => {
            targetAffinity = 4;
            physical = 0;
            opposingAffinity = 2;
        },
        5 => {
            targetAffinity = 5;
            physical = 0;
            opposingAffinity = 6;
        },
        6 => {
            targetAffinity = 6;
            physical = 0;
            opposingAffinity = 5;
        },
        else => {},
    }

    const t: usize = @intCast(targetAffinity);
    if (aff[t] >= 100) {
        return;
    }

    var randVal = c.vs_main_getRand(256);

    if ((70 -% @divTrunc(@as(c_int, aff[t]) +% 100, 4)) < randVal) {
        return;
    }

    aff[t] +%= 1;

    if (notify) {
        c.func_80096768(arg3, targetAffinity +% 6, 1);
    }

    if (targetAffinity == 0) {
        var i: c_int = 1;
        while (i < 7) : (i +%= 1) {
            const ii: usize = @intCast(i);
            if (aff[ii] > -100) {
                const r = c.vs_main_getRand(256);
                if ((@divTrunc(@as(c_int, aff[ii]) +% 100, 4) +% 20) >= r) {
                    aff[ii] -%= 1;
                    // 0x80000001 passed as an int argument.
                    if (notify) {
                        c.func_80096768(arg3, i +% 6, -0x7FFFFFFF);
                    }
                }
            }
        }
        return;
    }

    const ph: usize = @intCast(physical);
    if (aff[ph] > -100) {
        randVal = c.vs_main_getRand(256);
        if ((@divTrunc(@as(c_int, aff[ph]) +% 100, 4) +% 20) >= randVal) {
            aff[ph] -%= 1;
            if (notify) {
                c.func_80096768(arg3, physical +% 6, -0x7FFFFFFF);
            }
        }
    }

    const op: usize = @intCast(opposingAffinity);
    if (aff[op] > -100) {
        randVal = c.vs_main_getRand(256);
        if ((@divTrunc(@as(c_int, aff[op]) +% 100, 4) +% 20) >= randVal) {
            aff[op] -%= 1;
            if (notify) {
                c.func_80096768(arg3, opposingAffinity +% 6, -0x7FFFFFFF);
            }
        }
    }
}
