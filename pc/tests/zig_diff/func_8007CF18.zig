//! zig_diff spec: func_8007CF18 -> func_8007CF18.func_8007CF18 (146C.c).
//! Inputs: an arg0 from edges (0, small, -1, 0xFFFF, 0x10000, 0x10001, -65536,
//! INT_MAX, INT_MIN) that a truncating port would confuse with a slot's unk18;
//! the 16 vs_battle_actors slots each NULL or an arena actor whose unk18 is
//! arg0 (exact only when arg0 fits u16), a truncated decoy of arg0, or an edge
//! value; one slot sometimes forced to hold the match, at any index 0-15.
//! No callees: the C only reads the table and the actors.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CF18));

pub const classes = [_][:0]const u8{ "no-match", "first-slot", "last-slot", "middle-slot", "null-before-match" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 2, 15, 16, 0xFFFF, 0x10000, 0x10001, -65536, 0x7FFF_FFFF, -0x8000_0000 });
    const fits = arg0 >= 0 and arg0 <= 0xFFFF;
    const low: u16 = @truncate(@as(u32, @bitCast(arg0)));
    const hit: ?usize = if (ctx.chance(4)) null else ctx.range(usize, 0, 15);
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const is_hit = if (hit) |h| h == i else false;
        if (!is_hit and ctx.chance(4)) {
            table[i] = null;
            continue;
        }
        const a = ctx.alloc(v.vs_battle_actor);
        if (is_hit and fits) {
            a.unk18 = @intCast(arg0);
        } else if (ctx.chance(3)) {
            a.unk18 = low;
        } else {
            a.unk18 = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
        }
        table[i] = a;
    }
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    const table = v.g.vs_battle_actors();
    var first: ?usize = null;
    var nulls_before = false;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const p = table[i] orelse {
            if (first == null) nulls_before = true;
            continue;
        };
        if (@as(c_int, p.unk18) == arg0) {
            first = i;
            break;
        }
    }
    const f = first orelse return 0;
    if (f == 0) return 1;
    if (f == 15) return 2;
    if (nulls_before) return 4;
    return 3;
}
