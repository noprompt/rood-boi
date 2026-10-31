//! Inserts a new node into the sorted list headed by D_800F54B0 (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF55C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Allocates a node, fills it from `arg0` and links it into the list in order of `arg0.unk10`.
pub fn func_800CF55C(arg0: ?*v.D_800F53B8_t2) callconv(.c) ?*v.D_800F53B8_t {
    const raw = c.vs_main_allocHeapR(@sizeOf(v.D_800F53B8_t)).?;
    const temp: *v.D_800F53B8_t = @ptrCast(@alignCast(raw));
    c.func_800CE714(@ptrCast(arg0), @ptrCast(temp));

    const a1: ?*v.D_800F53B8_t = v.g.D_800F54B0().*;

    if (a1 == null or arg0.?.unk10 < @as(c_int, a1.?.unk9)) {
        psx.put(&temp.next, a1);
        v.g.D_800F54B0().* = temp;
    } else {
        var cur: *v.D_800F53B8_t = a1.?;
        while (true) {
            const next_ = psx.get(cur.next);
            if (next_ == null or arg0.?.unk10 < @as(c_int, next_.?.unk9)) {
                psx.put(&temp.next, next_);
                psx.put(&cur.next, temp);
                break;
            }
            cur = next_.?;
        }
    }
    return temp;
}
