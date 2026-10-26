//! zig_diff spec: _getLocationId -> get_location_id.getLocationId (146C.c).
//! Inputs: the 512-entry zone/map table (vs_main_locationZoneMapIds, 1024
//! bytes) is filled per run with a planted (zone, map) pair at an edge or
//! random index (0, 1, 255, 510, 511 included), so matches land in both
//! halves and at the last entry. Other cases plant a zone-only match (map
//! off by one), a zone 256 above the planted one (only a truncating compare
//! would match), a negative zone, or no match at all (the loop runs to 512
//! and returns 0). Both arguments are c_int, so the u8 table compare with
//! wide values is exercised.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getLocationId));

pub const classes = [_][:0]const u8{ "no-zone", "zone-only", "match-low", "match-high" };

fn find(zone: c_int, map: c_int) ?usize {
    const t = v.g.vs_main_locationZoneMapIds();
    var i: usize = 0;
    while (i < 512) : (i += 1) {
        if (zone == @as(c_int, t[i * 2]) and map == @as(c_int, t[i * 2 + 1])) return i;
    }
    return null;
}

fn zoneSeen(zone: c_int) bool {
    const t = v.g.vs_main_locationZoneMapIds();
    var i: usize = 0;
    while (i < 512) : (i += 1) {
        if (zone == @as(c_int, t[i * 2])) return true;
    }
    return false;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const t = v.g.vs_main_locationZoneMapIds();
    const k: usize = if (ctx.chance(2))
        ctx.edge(usize, &.{ 0, 1, 255, 510, 511 })
    else
        ctx.range(usize, 0, 511);
    const z = ctx.int(u8);
    const m = ctx.int(u8);
    var zone: c_int = z;
    var map: c_int = m;
    switch (ctx.range(u8, 0, 9)) {
        0...3 => {
            t[2 * k] = z;
            t[2 * k + 1] = m;
        },
        4 => {
            // zone matches, map does not
            t[2 * k] = z;
            t[2 * k + 1] = m +% 1;
        },
        5 => {
            // a planted match that only a truncating compare would find
            t[2 * k] = z;
            t[2 * k + 1] = m;
            zone = @as(c_int, z) + 256;
        },
        6 => {
            // negative zone: never equal to a u8 entry
            t[2 * k] = z;
            t[2 * k + 1] = m;
            zone = -@as(c_int, z) - 1;
        },
        else => {
            // no match: the loop runs to 512 and returns 0 (usually)
            zone = ctx.pick(c_int, &.{ 0, 255, 256, -1, 0x7fff_ffff, -0x8000_0000 });
            map = ctx.pick(c_int, &.{ 0, 255, 256, -1, 0x7fff_ffff, -0x8000_0000 });
        },
    }
    return .{ zone, map };
}

pub fn classify(args: Args) usize {
    const zone = args[0];
    const map = args[1];
    if (find(zone, map)) |idx| {
        return if (idx < 256) 2 else 3;
    }
    return if (zoneSeen(zone)) 1 else 0;
}
