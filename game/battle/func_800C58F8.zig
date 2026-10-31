//! The battle target-selection menu: moves the cursor, fills the description box and reports the chosen target (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// The battle state block (D_800EB9B8), dereferenced.
fn battleState() *v.func_800C56C0_t {
    return v.g.D_800EB9B8().*.?;
}

/// The current selection's slot in the battle state's 24-entry array.
fn slotAt(idx: c_int) *v.func_800C56C0_t2 {
    return psx.at(&battleState().unk990, idx);
}

/// The slot at the current cursor position (`D_800EB9B8->unk990[D_800EB9B8->unk2D]`).
fn curSlot() *v.func_800C56C0_t2 {
    return slotAt(@as(c_int, battleState().unk2D));
}

/// `psx_get(D_800EB9B8->unk40)[idx]`.
fn entryAt(idx: c_int) *v.func_800C5798_t {
    return psx.at(psx.get(battleState().unk40).?, idx);
}

/// `vs_battle_actors[idx]`, dereferenced.
fn actorAt(idx: c_int) *v.vs_battle_actor {
    return psx.at(v.g.vs_battle_actors(), idx).*.?;
}

/// `D_800F4C70[row][k]`.
fn tableC70(row: usize, k: c_int) c_int {
    const tbl = v.g.D_800F4C70();
    return psx.at(&tbl[row], k).*;
}

/// An 8-entry byte table indexed by `k`.
fn arr8(p: *[8]u8, k: c_int) c_int {
    return psx.at(p, k).*;
}

/// A byte global's value, widened the way C promotes it.
fn byteVal(p: *u8) c_int {
    return p.*;
}

/// The pad's pressed-buttons word.
fn pressed() u32 {
    return v.g.vs_main_buttonsPressed().all;
}

/// The pad's auto-repeat word.
fn repeatBits() i32 {
    return v.g.vs_main_buttonRepeat().*;
}

/// `vs_battle_stringContext.strings[slot] = (char*)&vs_battle_statusStrings[vs_battle_statusStrings[idx]]`.
fn putStatus(slot: usize, idx: c_int) void {
    const ss = v.g.vs_battle_statusStrings();
    psx.put(&v.g.stringContext().strings[slot], psx.at(ss, psx.at(ss, idx).*));
}

/// Closes the menu's text box and the menu itself; the menu is done.
fn finishMenu() c_int {
    _ = c.vs_battle_dismissTextBox(7);
    c.func_800C06E0();
    return 1;
}

/// One row's slot: its `unk7` follows the slot before it in the row.
fn setRowItem(row: usize, mode: c_int) void {
    const i = tableC70(row, v.g.D_800EABAA().*);
    const item: ?*v.func_800C56C0_t2 = @ptrCast(@alignCast(c.func_800C5798(i, mode, v.g.D_800EABAA().*)));
    if (v.g.D_800EABAA().* != 0) {
        const prev = tableC70(row, @as(c_int, v.g.D_800EABAA().*) - 1);
        if (entryAt(i).unk9 != entryAt(prev).unk9) {
            item.?.unk7 = psx.conv(u8, @as(c_int, 1) -% @as(c_int, slotAt(prev).unk7));
        } else {
            item.?.unk7 = slotAt(prev).unk7;
        }
    }
}

/// The cursor-movement and description state (state 19 of the menu).
fn caseNineteen(target: [*c]u8) void {
    curSlot().unk1[2] +%= 1;
    if (curSlot().unk1[2] == 0x22) curSlot().unk1[2] = 0x12;
    curSlot().unk1[0] = 0;

    if ((pressed() & 0x40) != 0) {
        c.vs_battle_playMenuLeaveSfx();
        c.func_800C56C0();
        v.g.D_800EB9AC().* = @intFromBool(battleState().unk0.unk1 == 2);
        v.g.D_800EABAA().* = 21;
        return;
    }
    target[0] = battleState().unk2D;
    if ((pressed() & 0x20) != 0) {
        c.func_800C56C0();
        v.g.D_800EABAA().* = 20;
        return;
    }

    const prev: c_int = battleState().unk2D;
    var pos: c_int = prev;
    const cb0 = byteVal(v.g.D_800F4CB0());
    const cb1 = byteVal(v.g.D_800F4CB1());
    const cb2 = byteVal(v.g.D_800F4CB2());
    const cb3 = byteVal(v.g.D_800F4CB3());

    chain: {
        if ((repeatBits() & 1) != 0) {
            const kind: c_int = entryAt(prev).unk9;
            var i: c_int = 0;
            while (i < cb3) : (i += 1) {
                if (arr8(v.g.D_800F4C98(), i) == kind) break;
            }
            if (i != cb3) {
                i += 1;
                if (i == cb3) {
                    if (cb2 != 0) pos = tableC70(1, 0);
                    break :chain;
                }
                pos = arr8(v.g.D_800F4CA8(), i);
                break :chain;
            }
            i = 0;
            while (i < cb2) : (i += 1) {
                if (arr8(v.g.D_800F4C90(), i) == kind) break;
            }
            i += 1;
            if (i == cb2) {
                pos = tableC70(0, 0);
                break :chain;
            }
            pos = arr8(v.g.D_800F4CA0(), i);
            break :chain;
        }

        var i: c_int = 0;
        while (i < cb1) : (i += 1) {
            if (tableC70(0, i) == prev) break;
        }
        if (i != cb1) {
            if ((pressed() & 0x8000) != 0 and cb0 != 0) {
                if (i >= cb0) i = cb0 - 1;
                pos = tableC70(1, i);
                break :chain;
            }
            if ((repeatBits() & 0x1000) != 0) {
                if (i == 0) {
                    if (cb0 != 0) {
                        pos = tableC70(1, cb0 - 1);
                        break :chain;
                    }
                    i = cb1 - 1;
                } else {
                    i -= 1;
                }
            }
            if ((repeatBits() & 0x4000) != 0) {
                if (i != cb1 - 1) {
                    i += 1;
                } else {
                    i = 0;
                    if (cb0 != 0) {
                        pos = tableC70(1, 0);
                        break :chain;
                    }
                }
            }
            pos = tableC70(0, i);
            break :chain;
        }

        i = 0;
        while (i < cb0) : (i += 1) {
            if (tableC70(1, i) == prev) break;
        }
        if ((pressed() & 0x2000) != 0) {
            if (i >= cb1) i = cb1 - 1;
            pos = tableC70(0, i);
            break :chain;
        }
        if ((repeatBits() & 0x1000) != 0) {
            if (i == 0) {
                pos = tableC70(0, cb1 - 1);
                break :chain;
            }
            i -= 1;
        }
        if ((repeatBits() & 0x4000) != 0) {
            if (i == cb0 - 1) {
                pos = tableC70(0, 0);
                break :chain;
            }
            i += 1;
        }
        pos = tableC70(1, i);
    }

    battleState().unk2D = psx.conv(u8, pos);
    curSlot().unk1[0] = 1;
    if (prev != @as(c_int, battleState().unk2D)) {
        curSlot().unk1[2] = 0;
        c.vs_battle_playMenuChangeSfx();
        c.func_800C51B4(3);
    }

    const entry = entryAt(@as(c_int, battleState().unk2D));
    const unk9: c_int = entry.unk9;
    const type_: c_int = entry.unk8;

    if ((unk9 >> 4) != 0) {
        putStatus(0, (unk9 >> 5) + c.VS_statusStrings_INDEX_blocker);
    } else if (type_ == 16) {
        const stats = psx.get(actorAt(unk9).stats).?;
        psx.put(&v.g.stringContext().strings[0], &stats.name);
    } else {
        putStatus(0, type_);
    }

    var k: usize = 1;
    while (k < 6) : (k += 1) {
        psx.put(&v.g.stringContext().strings[k], v.g.D_800EAA54());
    }

    var value: c_int = entry.unkB;
    if (type_ == 16 and (unk9 >> 4) == 0 and (actorAt(unk9).allegiance & 0x10) != 0) {
        value = 5;
        putStatus(1, if (entry.unkE == 0) c.VS_statusStrings_INDEX_indestructable else c.VS_statusStrings_INDEX__3);
    } else if (value == 0x3A) {
        value = 1;
    } else if (value == 0x3B) {
        value = 2;
    } else if (value == 0x3E) {
        value = 3;
    } else if (value == 0x3F) {
        value = 4;
    } else {
        psx.put(&v.g.stringContext().strings[1], v.g.D_800EA9B6());
        psx.put(&v.g.stringContext().strings[6], c._getStatusString(entry.unk10));
        value = 0;
    }
    putStatus(2, @as(c_int, entry.unk14) + c.VS_statusStrings_INDEX_indestructable);
    if (value != 0) {
        if (value < 5) {
            putStatus(1, c.VS_statusStrings_INDEX_mpTemplate - (value & 1));
            putStatus(5, @as(c_int, entry.unk17) + c.VS_statusStrings_INDEX_human);
        }
        putStatus(3, @as(c_int, entry.unk15) + c.VS_statusStrings_INDEX_empty);
        putStatus(4, @as(c_int, entry.unk16) + c.VS_statusStrings_INDEX_physical);
    }
    v.g.stringContext().integers[0] = @as(i32, entry.unkC);
    v.g.stringContext().integers[1] = @as(i32, entry.unkE);
    _ = c.vs_battle_printf(@ptrCast(psx.byteAt(u8, battleState(), 0x4A54)), v.g.D_800EA984());
    _ = c.vs_battle_setTextBox(7, @ptrCast(psx.byteAt(u8, battleState(), 0x4A54)));
}

/// orig: func_800C58F8 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Runs one frame of the target-selection menu, writing the highlighted target to `target`; returns 1 when the menu closes.
pub fn func_800C58F8(target: [*c]u8) callconv(.c) c_int {
    if (target == null) {
        v.g.D_800EABAA().* = 0;
        return 0;
    }
    if (v.g.D_800EABAA().* == 0) {
        battleState().unk34 = 0x808080;
        c.vs_battle_initInformationTextBox(0);
        c.func_800C51B4(2);
        c.func_800C553C();
        if (battleState().unk2C == 0) {
            v.g.D_800EABAA().* = 16;
        }
    }

    target[0] = 0xFF;

    if (v.g.D_800EABAA().* < 16) {
        if (v.g.D_800EABAA().* >= v.g.D_800F4CB1().* and v.g.D_800EABAA().* >= v.g.D_800F4CB0().*) {
            v.g.D_800EABAA().* = 18;
        } else {
            if (v.g.D_800EABAA().* < v.g.D_800F4CB1().*) {
                setRowItem(0, 2);
            }
            if (v.g.D_800EABAA().* < v.g.D_800F4CB0().*) {
                setRowItem(1, 3);
            }
            v.g.D_800EABAA().* +%= 1;
        }
    } else {
        switch (v.g.D_800EABAA().*) {
            16 => {
                psx.setBits(&v.g.textBoxes()[7].unk0, "unk0_8", 1);
                const sm = v.g.sceneMessages();
                _ = c.vs_battle_setTextBox(7, @ptrCast(psx.at(sm, psx.at(sm, 0).*)));
                if ((pressed() & 0x60) != 0) {
                    c.vs_battle_playMenuLeaveSfx();
                    v.g.D_800EABAA().* = 17;
                }
            },
            17 => {
                v.g.D_800EB9AC().* = @intFromBool(battleState().unk0.unk1 == 2);
                v.g.D_800EABAA().* = 21;
            },
            18 => {
                if (c.func_800C1D84() != 0) {
                    v.g.D_800EABAA().* +%= 1;
                }
            },
            19 => {
                caseNineteen(target);
            },
            20 => {
                target[0] = battleState().unk2D;
                return finishMenu();
            },
            21 => {
                return finishMenu();
            },
            else => {},
        }
    }
    return 0;
}
