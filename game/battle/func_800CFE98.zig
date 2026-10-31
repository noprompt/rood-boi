//! Stores a short vector into a record's vector after its base setup (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CFE98 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Runs func_800CFE7C on the record, then copies the short vector into its unk14 vector.
pub fn func_800CFE98(arg0: ?*v.SVECTOR, arg1: ?*v.func_800CFE98_t) callconv(.c) void {
    c.func_800CFE7C(@ptrCast(arg1));
    const vector = arg0.?;
    const record = arg1.?;
    record.unk14.vx = psx.conv(i32, vector.vx);
    record.unk14.vy = psx.conv(i32, vector.vy);
    record.unk14.vz = psx.conv(i32, vector.vz);
}
