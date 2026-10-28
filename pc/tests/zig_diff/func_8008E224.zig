//! zig_diff spec: func_8008E224 -> func_8008E224.func_8008E224 (146C.c).
//! Inputs: vs_battle_roomData.section12 is either NULL or a 16-entry block of
//! _mpdRoomSection12 in the arena, with its base four entries in, so the index
//! arg0 from -4 to 11 stays inside the block (negative indices included). arg1
//! is an edge value or any int; its parity picks the bit the C writes
//! (arg1 - 1 odd sets unk0_9, even clears it). The callee func_8009195C returns
//! NULL or an arena int that the C then ANDs or ORs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E224));

pub const classes = [_][:0]const u8{ "no-section", "clear-bit", "set-bit" };

const slots = 16;
const lead = 4;

pub const stubs = struct {
    /// The real callee returns NULL or a pointer to an int it may have
    /// rewritten, so the stub writes a fresh value into the int it hands back.
    pub fn func_8009195C(ctx: *zd.Ctx, arg: anytype) [*c]c_int {
        _ = arg;
        if (ctx.value(u2) == 0) return null;
        const p = ctx.alloc(c_int);
        p.* = ctx.value(c_int);
        return p;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    if (ctx.chance(6)) {
        const none: ?*v._mpdRoomSection12 = null;
        psx.put(&room.section12, none);
    } else {
        const size = @sizeOf(v._mpdRoomSection12);
        const buf = ctx.allocBytes(slots * size, 16);
        const base: *v._mpdRoomSection12 = @ptrCast(@alignCast(buf + lead * size));
        psx.put(&room.section12, base);
    }
    const arg0 = ctx.range(c_int, -lead, slots - lead - 1);
    const arg1 = ctx.pick(c_int, &.{ 0, 1, 2, -1, 3, 0x7fffffff });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    if (psx.get(room.section12) == null) return 0;
    // arg1 - 1 odd (arg1 even) sets unk0_9; arg1 - 1 even (arg1 odd) clears it.
    return if ((args[1] & 1) != 0) 1 else 2;
}
