//! Battle class changes: a class rises by a random chance and its two opposing classes may fall (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _triggerClassChange (src/BATTLE/BATTLE.PRG/146C.c)
/// Raises an equipment's class by a random chance and lowers its two opposing classes by chance.
pub fn triggerClassChange(_: ?*v.vs_action_t, equipment: ?*v.vs_battle_uiEquipment, class: c_int, arg3: c_int, actorId: c_int) callconv(.c) void {
    const eq = equipment.?;

    // Other classes leave the opposing pair uninitialised in the original; the object takes the last case's values.
    var opposingClass0: c_int = 5;
    var opposingClass1: c_int = 0;
    switch (class) {
        0 => {
            opposingClass0 = 1;
            opposingClass1 = 2;
        },
        1 => {
            opposingClass0 = 2;
            opposingClass1 = 3;
        },
        2 => {
            opposingClass0 = 3;
            opposingClass1 = 4;
        },
        3 => {
            opposingClass0 = 4;
            opposingClass1 = 5;
        },
        4 => {
            opposingClass0 = 5;
            opposingClass1 = 0;
        },
        else => {
            opposingClass0 = 0;
            opposingClass1 = 1;
        },
    }

    const targetClass = class;
    const target = psx.at(&eq.classes, targetClass);
    if (target.* >= 100) {
        return;
    }

    const randVal = c.vs_main_getRand(256);

    if (70 -% @divTrunc(@as(c_int, target.*) +% 100, 4) >= randVal) {
        target.* +%= 1;

        if (actorId == 0) {
            c.func_80096768(arg3, targetClass, 1);
        }

        const opp0 = psx.at(&eq.classes, opposingClass0);
        if (opp0.* > -100) {
            const innerRand = c.vs_main_getRand(256);

            if (@divTrunc(@as(c_int, opp0.*) +% 100, 4) +% 20 >= innerRand) {
                opp0.* -%= 1;

                if (actorId == 0) {
                    c.func_80096768(arg3, opposingClass0, psx.conv(c_int, @as(c_uint, 0x8000_0001)));
                }
            }
        }

        const opp1 = psx.at(&eq.classes, opposingClass1);
        if (opp1.* > -100) {
            const innerRand = c.vs_main_getRand(256);

            if (@divTrunc(@as(c_int, opp1.*) +% 100, 4) +% 20 >= innerRand) {
                opp1.* -%= 1;

                if (actorId == 0) {
                    c.func_80096768(arg3, opposingClass1, psx.conv(c_int, @as(c_uint, 0x8000_0001)));
                }
            }
        }
    }
}
