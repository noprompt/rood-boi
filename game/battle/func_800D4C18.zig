//! Per-frame update of the battle effect list: ages each node, fires its tick and end events, and expires it (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D4C18 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Advances every effect node on the list: ages it, fires its tick event, counts its lifetime down and ends it.
pub fn func_800D4C18(arg0: ?*v.D_800F53B8_t) callconv(.c) c_int {
    const a = arg0.?;
    var next: ?*v.func_800D2904_t = psx.get(a.unk18);

    c.func_800D52A4(@ptrCast(next));
    // ROOD_PC: the head is read again after the call, as the C reads arg0->unk18 twice.
    c.func_800D6E44(@ptrCast(psx.get(a.unk18)));

    var node: ?*v.func_800D2904_t = next;
    while (next != null) {
        const n = node.?;
        next = psx.get(n.next);
        n.unk74.fields.age +%= 1;
        if (n.tickEvent != 0) {
            c.func_800D2ADC(@ptrCast(a), @as(c_int, n.tickEvent) -% 1, 0, 0, @ptrCast(n));
        }
        if (n.lifetime == -1) {
            if (psx.byteAt(u8, n, 0x42).* == 0) {
                if (n.endEvent != 0) {
                    c.func_800D2ADC(@ptrCast(a), @as(c_int, n.endEvent) -% 1, 0, 0, @ptrCast(n));
                }
                c.func_800D2888(@ptrCast(n), @ptrCast(a));
            }
        } else {
            n.lifetime -%= 1;
            if (n.lifetime == 0) {
                if (n.endEvent != 0) {
                    c.func_800D2ADC(@ptrCast(a), @as(c_int, n.endEvent) -% 1, 0, 0, @ptrCast(n));
                }
                c.func_800D2888(@ptrCast(n), @ptrCast(a));
            }
        }
        node = next;
    }
    return 1;
}
