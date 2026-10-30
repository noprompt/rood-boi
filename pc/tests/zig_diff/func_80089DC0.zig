//! zig_diff spec: func_80089DC0 -> func_80089DC0.func_80089DC0 (146C.c).
//! Inputs: the MPD CD slot still queued or loaded (the wait loop runs or
//! not), the slot absent at entry (_loadMpd puts it), the MPD header in the
//! arena with small section offsets and lengths of every sign, the loot
//! section present or not, zone/map 27/1 or not, the scene equal to the zone
//! context's unk68 or not, collision dimensions at 0, -1 and random (so the
//! `< 0` test sees equal sides), map bounds present or null, startState 1 or
//! not, the transition effect 3 or not, the camera distance 1536 or not, the
//! door-script result with its low 16 bits zero or not, the blocked-call
//! result 1 or not, and D_800F18AC zero, negative or positive.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089DC0));

pub const classes = [_][:0]const u8{ "cd-null", "bounds-null", "zone27-map1", "other" };

var cdSlot: *v.vs_main_CdQueueSlot = undefined;
var mpdHeader: *v._mpdHeader = undefined;
var bounds: *v._zoneContextBounds = undefined;
var boundsNull: bool = false;
var scene: i32 = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    const zc = v.g._zoneContext();
    const room = v.g.D_800F1AB0();

    cdSlot = ctx.alloc(v.vs_main_CdQueueSlot);
    cdSlot.state = if (ctx.chance(2)) 4 else ctx.pick(i16, &.{ 0, 1, 2, 3, 5, -1 });
    const none: ?*v.vs_main_CdQueueSlot = null;
    if (ctx.chance(3)) {
        psx.put(&zc.mpdCdFile, none);
    } else {
        psx.put(&zc.mpdCdFile, cdSlot);
    }

    // Small offsets: the C adds them to a pointer-sized address.
    mpdHeader = ctx.alloc(v._mpdHeader);
    mpdHeader.roomSectionOffset = ctx.pick(i32, &.{ 0, 4, -4, 0x1000 });
    mpdHeader.clearedSectionOffset = ctx.pick(i32, &.{ 0, 4, -4, 0x1000 });
    mpdHeader.clearedSectionLen = ctx.pick(u16, &.{ 0, 1, 0xFFFF });
    mpdHeader.scriptSectionOffset = ctx.pick(i32, &.{ 0, 4, -4, 0x1000 });
    mpdHeader.scriptSectionLen = ctx.pick(u16, &.{ 0, 1, 0xFFFF });
    mpdHeader.doorSectionOffset = ctx.pick(i32, &.{ 0, 4, -4, 0x1000 });
    mpdHeader.doorSectionLen = ctx.pick(u16, &.{ 0, 1, 0xFFFF });
    mpdHeader.enemySectionOffset = ctx.pick(i32, &.{ 0, 4, -4, 0x1000 });
    mpdHeader.enemySectionLen = ctx.pick(i32, &.{ 0, 1, -1 });
    mpdHeader.lootSectionOffset = ctx.pick(i32, &.{ 0, 4, -4, 0x1000 });
    mpdHeader.lootSectionLen = ctx.pick(i32, &.{ 0, 1, -1 });
    psx.put(&zc.mpdData, mpdHeader);

    room.zndId = ctx.pick(u8, &.{ 27, 0, 26 });
    room.mpdId = ctx.pick(u8, &.{ 1, 0, 2 });

    scene = ctx.pick(i32, &.{ 0, 1, -1 });
    zc.unk68 = if (ctx.chance(2)) scene else ctx.pick(i32, &.{ 0, 7 });

    bounds = ctx.alloc(v._zoneContextBounds);
    boundsNull = ctx.chance(2);

    v.g.D_80050468().unk2 = if (ctx.chance(2)) 0 else ctx.pick(u16, &.{ 1, 0xFFFF });
    v.g.vs_main_startState().* = if (ctx.chance(2)) 1 else ctx.pick(i32, &.{ 0, 2, 5, -1 });
    v.g.vs_battle_screenTransitionEffect().* = if (ctx.chance(2)) 3 else ctx.pick(i32, &.{ 0, 2, -1 });
    v.g.vs_battle_cameraCurrentSpherical().initialDistance = if (ctx.chance(2)) 1536 else ctx.pick(i32, &.{ 0, 4096, -1 });
    v.g.D_800F18AC().* = ctx.pick(i32, &.{ 0, 1, -1, -0x8000_0000 });

    // The C always reads the character's stats: never null.
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    stats.statuses = ctx.pick(i32, &.{ 0, 0x21000, -1 });
    v.g.vs_battle_characterState().* = actor;

    return .{ctx.pick(c_int, &.{ 0, 1, -1 })};
}

pub fn classify(args: Args) usize {
    _ = args;
    const zc = v.g._zoneContext();
    if (psx.rawOf(zc.mpdCdFile) == 0) return 0;
    if (boundsNull) return 1;
    const room = v.g.D_800F1AB0();
    if (room.zndId == 27 and room.mpdId == 1) return 2;
    return 3;
}

pub const stubs = struct {
    // The wait loop ends when the slot reaches CdQueueStateLoaded (4).
    pub fn vs_main_gametimeUpdate(ctx: *zd.Ctx, vsync: anytype) c_int {
        _ = vsync;
        if (ctx.value(u8) < 128) cdSlot.state = 4;
        return 0;
    }

    // Loads the MPD: sets the CD slot and the header the C reads back.
    pub fn _loadMpd(ctx: *zd.Ctx, arg0: anytype) void {
        _ = ctx;
        _ = arg0;
        const zc = v.g._zoneContext();
        psx.put(&zc.mpdCdFile, cdSlot);
        psx.put(&zc.mpdData, mpdHeader);
    }

    // Scene id: equal to unk68 in half of the runs (prepare sets it).
    pub fn vs_battle_getCurrentSceneId(ctx: *zd.Ctx) c_int {
        _ = ctx;
        return scene;
    }

    // Edge values: 0 and -1 are drawn often, so the `< 0` test sees equal sides.
    pub fn _getCollisionMapDimensions(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        const sel = ctx.value(u8);
        if (sel < 64) return 0;
        if (sel < 96) return -1;
        return ctx.value(i32);
    }

    // The C dereferences the result again: the same answer both times (prepare sets it).
    pub fn _getMapBounds(ctx: *zd.Ctx, arg0: anytype) [*c]v._zoneContextBounds {
        _ = ctx;
        _ = arg0;
        if (boundsNull) return null;
        return bounds;
    }

    // Result tested as `(x << 16) != 0`: a quarter of the time the low 16 bits are zero.
    pub fn _loadMpdClearedScriptDoorSections(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype, e: anytype, f: anytype, g: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        _ = e;
        _ = f;
        _ = g;
        if (ctx.value(u2) == 0) return ctx.value(i32) & -65536;
        return ctx.value(i32);
    }

    // Tested as `== 1`: a quarter of the time it is 1.
    pub fn func_800BEC58(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype) c_short {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        if (ctx.value(u2) == 0) return 1;
        return ctx.value(i16);
    }

    // Writes the out-parameter sp40 the C reads back.
    pub fn func_800A1108(ctx: *zd.Ctx, arg0: anytype, out: anytype) c_int {
        _ = arg0;
        const p: *v.func_8006EBF8_t = @ptrCast(@alignCast(out));
        p.unk0.unk4.vx = ctx.value(i16);
        p.unk0.unk4.vy = ctx.value(i16);
        p.unk0.unk4.vz = ctx.value(i16);
        p.unk0.unk0.value = ctx.value(i32);
        return ctx.value(i32);
    }

    // Writes the out-parameter lookAt the C stores into the scratchpad.
    pub fn _clampPositionToZoneBounds(ctx: *zd.Ctx, pos: anytype, out: anytype) void {
        _ = pos;
        const p: *v.VECTOR = @ptrCast(@alignCast(out));
        p.vx = ctx.value(i32);
        p.vy = ctx.value(i32);
        p.vz = ctx.value(i32);
        p.pad = ctx.value(i32);
    }

    // Changes the spherical values and the camera position.
    pub fn _setCameraPositionFromAngles(ctx: *zd.Ctx, angles: anytype) void {
        const sv: *v._sphericalValues = @ptrCast(@alignCast(angles));
        sv.pitch = ctx.value(i32);
        v.g.vs_scratch().camera.position.vy = ctx.value(i32);
    }
};

test "spec compiles" {}
