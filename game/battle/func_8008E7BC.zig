//! The 146C flag lookup: finds a table entry matching a pair and returns its state flag (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// D_800E84AC[i][k] (char[][4]): the static helper get_D_800E84AC, carried here.
fn tableEntry(i: c_int, k: c_int) c_int {
    return @as(c_int, psx.at(psx.globalMany(u8, "D_800E84AC"), i *% 4 +% k).*);
}

/// orig: func_8008E7BC (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the state flag of the first entry in group arg2 whose (0,1) or (2,3) pair matches arg0, arg1; else 0.
pub fn func_8008E7BC(arg0: c_int, arg1: c_int, arg2: c_uint) callconv(.c) c_int {
    var i: c_int = @as(c_int, psx.at(v.g.D_800E849C(), arg2).*);
    while (i < @as(c_int, psx.at(v.g.D_800E849C(), arg2 +% 1).*)) : (i +%= 1) {
        if ((tableEntry(i, 0) == arg0 and tableEntry(i, 1) == arg1) or
            (tableEntry(i, 2) == arg0 and tableEntry(i, 3) == arg1))
        {
            return @as(c_int, psx.at(&v.g.vs_main_stateFlags().unk186, i).*);
        }
    }
    return 0;
}
