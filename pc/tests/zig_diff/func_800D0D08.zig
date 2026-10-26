//! zig_diff spec: func_800D0D08 -> func_800D0D08.func_800D0D08 (5BF94.c).
//! Inputs: a global D_800F569C_t in the arena whose block9 table gives a loop
//! count of 0, 1, 2, 3, 16, 17 or any byte, and whose block10 table holds 256
//! random definitions (every unk0 bit pattern). Each state in the arena array
//! gets edge actor and targetActor ids (0xFF, 0x12, others), small positions,
//! and in a quarter of them a forced "target equals world" setup (0x8040 set,
//! saved and attachment equal to the position, sometimes one axis off by one).
//! The callees are recording stubs that write the fields the C reads back
//! (matrices, saved vector, state position and facing) with ctx.value, and
//! return NULL where the real function returns a pointer.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D0D08));

pub const classes = [_][:0]const u8{ "no-defs", "single", "many", "target-actor-12" };

const max_defs = 256;

fn stateAt(obj: *v.D_800F53B8_t, i: usize) *v.effectTransformState {
    const base: [*]u8 = @ptrCast(obj);
    return @ptrCast(@alignCast(base + 0x1C + i * @sizeOf(v.effectTransformState)));
}

fn fillMatrix(ctx: *zd.Ctx, m: *v.MATRIX) void {
    for (&m.m) |*row| {
        for (row) |*e| {
            e.* = ctx.value(i16);
        }
    }
    for (&m.t) |*e| {
        e.* = ctx.value(i16);
    }
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F569C_t);
    v.g.D_800F569C().* = d;

    const count: u8 = ctx.pick(u8, &.{ 0, 1, 2, 3, 16, 17 });
    const b9 = ctx.alloc(v.pFileBlock9);
    b9.unk15 = count;
    psx.put(&d.block9Data, b9);

    const defs: [*]v.func_800D0B30_t = @ptrCast(@alignCast(ctx.allocBytes(max_defs * @sizeOf(v.func_800D0B30_t), 16)));
    psx.put(&d.block10Data, @as(*anyopaque, @ptrCast(defs)));

    const obj: *v.D_800F53B8_t = @ptrCast(@alignCast(ctx.allocBytes(0x1C + max_defs * @sizeOf(v.effectTransformState), 16)));

    for (0..max_defs) |i| {
        defs[i].unk0 = ctx.int(u16);
    }

    for (0..count) |i| {
        const def = &defs[i];
        const st = stateAt(obj, i);
        st.position.vx = ctx.int(i16);
        st.position.vy = ctx.int(i16);
        st.position.vz = ctx.int(i16);
        st.actor = ctx.pick(u8, &.{ 0xFF, 0, 0xFF, 1 });
        st.targetActor = ctx.pick(u8, &.{ 0xFF, 0x12, 0x12, 0, 5 });
        if (ctx.chance(4)) {
            def.unk0 |= 0x8040;
            st.saved.vx = @intCast(st.position.vx);
            st.saved.vy = @intCast(st.position.vy);
            st.saved.vz = @intCast(st.position.vz);
            st.attachment.t = .{ st.position.vx, st.position.vy, st.position.vz };
            switch (ctx.edge(u8, &.{ 0, 0, 1, 2 })) {
                1 => {
                    st.saved.vy +%= 1;
                    st.attachment.t[1] += 1;
                },
                2 => {
                    st.saved.vz +%= 1;
                    st.attachment.t[2] += 1;
                },
                else => {},
            }
        }
    }
    return .{obj};
}

pub fn classify(args: Args) usize {
    const obj = args[0].?;
    const d = v.g.D_800F569C().*.?;
    const count = psx.get(d.block9Data).?.unk15;
    if (count == 0) return 0;
    if (stateAt(obj, 0).targetActor == 0x12) return 3;
    return if (count == 1) 1 else 2;
}

pub const stubs = struct {
    pub fn func_800D0B30(ctx: *zd.Ctx, def: anytype, st: anytype, scratch: anytype) void {
        _ = def;
        const s: *v.SVECTOR = @ptrCast(@alignCast(st));
        s.vx = ctx.value(i16);
        const sc: *v.func_800D0B30_t2 = @ptrCast(@alignCast(scratch));
        fillMatrix(ctx, &sc.unk48);
    }

    pub fn func_800A1AF8(ctx: *zd.Ctx, actor: anytype, bone: anytype, saved: anytype, flag: anytype) void {
        _ = actor;
        _ = bone;
        _ = flag;
        if (ctx.value(u1) == 0) return;
        const s: *v.SVECTOR = @ptrCast(@alignCast(saved));
        s.vx = ctx.value(i16);
        s.vy = ctx.value(i16);
        s.vz = ctx.value(i16);
    }

    pub fn func_800D0C60(ctx: *zd.Ctx, addr: anytype, st: anytype) void {
        _ = addr;
        const s: *v.effectTransformState = @ptrCast(@alignCast(st));
        if (ctx.value(u1) == 1) s.position.vx = ctx.value(i16);
        if (ctx.value(u1) == 1) s.position.vy = ctx.value(i16);
    }

    pub fn func_800D0548(ctx: *zd.Ctx, def: anytype, st: anytype) void {
        _ = def;
        const s: *v.effectTransformState = @ptrCast(@alignCast(st));
        if (ctx.value(u1) == 1) s.facing.m[0][1] = ctx.value(i16);
        if (ctx.value(u1) == 1) s.attachment.t[2] = ctx.value(i16);
    }

    pub fn func_800D05F4(ctx: *zd.Ctx, def: anytype, st: anytype) void {
        _ = def;
        const s: *v.effectTransformState = @ptrCast(@alignCast(st));
        if (ctx.value(u1) == 1) s.saved.vz = ctx.value(i16);
        if (ctx.value(u1) == 1) s.attachment.m[1][1] = ctx.value(i16);
    }

    pub fn vs_battle_lookAt(ctx: *zd.Ctx, from: anytype, to: anytype, mat: anytype) void {
        _ = from;
        _ = to;
        const m: *v.MATRIX = @ptrCast(@alignCast(mat));
        fillMatrix(ctx, m);
    }

    pub fn CompMatrix(ctx: *zd.Ctx, m0: anytype, m1: anytype, m2: anytype) [*c]v.MATRIX {
        _ = m0;
        _ = m1;
        const out: *v.MATRIX = @ptrCast(@alignCast(m2));
        fillMatrix(ctx, out);
        return null;
    }
};
