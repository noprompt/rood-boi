//! zig_diff spec: func_8007F434 -> func_8007F434.func_8007F434 (146C.c).
//! Inputs: a battle actor whose stats block (reached through
//! vs_battle_characterState) carries a risk of any u16, with edges that put
//! the threshold below, at, and above the clamp at 100 (risks 104-109, and the
//! top of the u16 range). vs_main_getRand returns values near the C's
//! threshold (var_s0 + 20) so that `<` sees equal sides in about a third of
//! the runs, and otherwise any c_int, including negatives.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007F434));

pub const classes = [_][:0]const u8{ "below-100", "exactly-100", "clamped" };

/// The value vs_main_getRand returns most often: the C's threshold for this run.
var rand_edge: c_int = 0;

/// The C's threshold for a risk: the clamped percentage plus 20.
fn threshold(risk: u16) c_int {
    const t = @divTrunc((@as(c_int, risk) + 150) * 100, 256);
    return @min(t, 100) + 20;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    stats.risk = ctx.pick(u16, &.{ 0, 104, 105, 106, 107, 108, 109, 65535, 65386 });
    v.g.vs_battle_characterState().* = actor;
    rand_edge = threshold(stats.risk);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const actor = v.g.vs_battle_characterState().*.?;
    const risk = psx.get(actor.stats).?.risk;
    const t = @divTrunc((@as(c_int, risk) + 150) * 100, 256);
    if (t > 100) return 2;
    if (t == 100) return 1;
    return 0;
}

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: c_int) c_int {
        _ = n;
        return switch (ctx.value(u8) % 6) {
            0, 1 => rand_edge,
            2 => rand_edge - 1,
            3 => rand_edge + 1,
            else => ctx.value(c_int),
        };
    }
};
