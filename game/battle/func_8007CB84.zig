//! Fills a battle object-data record for a weapon model and populates its data slot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007CB84 (src/BATTLE/BATTLE.PRG/146C.c)
/// Populates a data slot with weapon model `wepId` at `index` for actor slot 1.
pub fn func_8007CB84(index: c_int, wepId: c_int) callconv(.c) void {
    // The C leaves the other fields of the record unwritten (stack garbage); so does the port.
    var objData: v.vs_battle_objectData = undefined;
    objData.dataType = 7;
    objData.index = psx.conv(i8, index);
    objData.modelId = psx.conv(i16, wepId);
    objData.actorId = 1;
    _ = c.vs_battle_populateDataSlot(@ptrCast(&objData));
}
