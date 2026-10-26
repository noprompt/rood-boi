//! zig_diff spec: vs_battle_loadMenuPrg -> load_menu_prg.loadMenuPrg (5BF94.c).
//! Inputs: an arg whose low five bits pick the sub-menu: 0, a table index below
//! 16 (the LBA table is 16 entries), or 31. The loaded-submenu global is the
//! same value, zero, a negative value, or another one. The load state is idle
//! or busy, the CD queue slot is Loaded or not, the shortcut flag is 5 or not,
//! D_800F4FDB takes 0, 1, 0x80 or 0xFF, the background buffer is null or set,
//! and the LBA table has sign-bit and wrapping values. The CD file the C
//! builds is copied into the queue slot by the allocate stub, so its lba and
//! size are compared through the state. The CD, heap and wait calls are
//! recording stubs that write what the real ones can change: the queue slot's
//! state, the menu flag the wait may set, and a null heap block.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").loadMenuPrg));

pub const classes = [_][:0]const u8{ "sub-31", "sub0-loaded", "start-load", "idle", "busy" };

pub const stubs = struct {
    pub fn vs_main_allocateCdQueueSlot(ctx: *zd.Ctx, file: anytype) [*c]v.vs_main_CdQueueSlot {
        const f: *const v.vs_main_CdFile = @ptrCast(@alignCast(file));
        const slot = ctx.alloc(v.vs_main_CdQueueSlot);
        slot.cdFile = f.*;
        slot.state = if (ctx.value(u8) < 160) 4 else ctx.value(i16);
        return slot;
    }

    pub fn vs_main_freeCdQueueSlot(ctx: *zd.Ctx, slot: anytype) void {
        _ = ctx;
        _ = slot;
    }

    pub fn vs_main_cdEnqueue(ctx: *zd.Ctx, slot: anytype, vram: anytype) void {
        _ = vram;
        if (ctx.value(u8) < 96) {
            const s: *v.vs_main_CdQueueSlot = @ptrCast(@alignCast(slot));
            s.state = ctx.value(i16);
        }
    }

    pub fn vs_main_wait(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 128) v.g.D_800F4FDB().* = ctx.value(u8);
    }

    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        _ = ctx;
        _ = p;
    }

    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        if (ctx.value(u8) < 32) return null;
        return @ptrCast(&zd.zdiff_arena[zd.arena_size - 0xB400]);
    }

    pub fn vs_mainMenu_initInventory(ctx: *zd.Ctx) void {
        _ = ctx;
    }

    pub fn vs_mainMenu_miscItemsShortcutMenu(ctx: *zd.Ctx, x: anytype) void {
        _ = ctx;
        _ = x;
    }

    pub fn vs_mainMenu_unpackMenubg(ctx: *zd.Ctx, buf: anytype) void {
        _ = ctx;
        _ = buf;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const sub: c_int = ctx.edge(c_int, &.{ 0, 0, 1, 2, 7, 15, 31 });
    const arg: c_int = (ctx.int(c_int) & ~@as(c_int, 0x1F)) | sub;

    const st = v.g.vs_battle_menuState();
    const slot = ctx.alloc(v.vs_main_CdQueueSlot);
    slot.state = if (ctx.chance(2)) 4 else ctx.int(i16);
    psx.put(&st.cdQueue, slot);
    st.loading = ctx.edge(u8, &.{ 0, 1 });

    const loaded = v.g._loadedSubMenu();
    const sub8: i8 = @intCast(sub);
    loaded.* = if (ctx.chance(3)) sub8 else ctx.pick(i8, &.{ 0, 0, -1, -128, 1, 5, 127 });

    const lbas = v.g._menuLbas();
    for (0..16) |i| {
        lbas[i] = ctx.pick(i32, &.{ 0, -1, -256, 0x7FFF_FFFF, std.math.minInt(i32), 0x100, 0xFF });
    }

    v.g.vs_battle_shortcutInvoked().* = if (ctx.chance(3)) 5 else ctx.pick(u8, &.{ 0, 4, 6, 255 });
    v.g.D_800F4FDB().* = ctx.edge(u8, &.{ 0, 1, 0x80, 0xFF });

    const buf: ?[*]u32 = if (ctx.chance(2)) null else @ptrCast(ctx.alloc(u32));
    v.g._menuBgUnpackedBuf().* = buf;

    const os = v.g.vs_overlay_slots();
    os.*[1] = ctx.alloc(u8);
    os.*[2] = ctx.alloc(u8);

    return .{arg};
}

pub fn classify(args: Args) usize {
    const sub: c_int = args[0] & 0x1F;
    if (sub == 31) return 0;
    const loaded: c_int = v.g._loadedSubMenu().*;
    if (sub == 0 and loaded > 0) return 1;
    if (loaded != sub) return 2;
    return if (v.g.vs_battle_menuState().loading == 0) 3 else 4;
}
