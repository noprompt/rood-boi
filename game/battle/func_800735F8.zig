//! Ends a battle command: runs the command's case (an ability execution or a cast), then the common tail (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800735F8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the command's case (5 nothing, 6-8 a cast, 10 an ability execution with its MP cost), then the common tail.
pub fn func_800735F8(command: ?*v.D_800F18EC_t) callconv(.c) void {
    const cmd = command.?;
    _ = c.func_8008B4C8(1);
    c.func_800CB660(v.g.vs_battle_characterState().*.?.weaponDrawn & 1);

    switch (@as(c_int, cmd.unk2)) {
        5 => {},
        6, 7, 8 => {
            c.func_80072EC4(0, psx.conv(u16, cmd.executeAbility.s32));
            return;
        },
        10 => {
            var sp18: v.func_8006EBF8_t = undefined;
            _ = c.func_800A1108(0, @ptrCast(&sp18));
            _ = c.func_8006F4B0(@ptrCast(&sp18.unk0));

            // ROOD_PC: fast travel (pc/src/fast_travel.c) decides the trip; the flag is set only when it begins.
            if (c.pc_fast_travel_begin(cmd.executeAbility.s32) != 0) {
                c.vs_battle_setStateFlag(0xB7, 1);
            }

            const fields = &cmd.executeAbility.fields;
            _ = c.func_8007C694(
                @as(c_int, psx.getBits(fields, "unk0_0")),
                @as(c_int, psx.getBits(fields, "unk0_9")),
                @as(c_int, psx.getBits(fields, "unk0_14")),
                0,
                8,
            );

            const actor = psx.get(v.g.vs_battle_characterState().*.?.stats).?;
            if (@as(c_int, actor.currentMP) >= @as(c_int, psx.getBits(fields, "unk0_19"))) {
                actor.currentMP = psx.conv(i16, @as(c_int, actor.currentMP) -% @as(c_int, psx.getBits(fields, "unk0_19")));
            }
            c.func_8009E070(0, null, 7);
        },
        else => {},
    }
    c.func_8006F5CC();
    c.func_800735CC(@ptrCast(command));
}
