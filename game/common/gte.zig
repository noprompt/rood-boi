//! The GTE macros as the PC build runs them (PORTING.md §8): one function per
//! `gte_*` macro, doing PsyCross's calls (pc/third_party/psycross/include/psx/
//! inline_c.h, plus pc/src/game/include/vs_inline_c.h for the `*2` variants) in the
//! same order, with the same register numbers and the same 32-bit loads and
//! stores. The registers are host state (`gteRegs`), compared by shadow mode.
//! Add a macro here when a port first needs it, copied from the header.

extern fn MTC2(value: c_uint, reg: c_int) callconv(.c) void;
extern fn CTC2(value: c_uint, reg: c_int) callconv(.c) void;
extern fn MFC2(reg: c_int) callconv(.c) c_uint;
extern fn doCOP2(op: c_int) callconv(.c) c_int;

/// `*(uint*)((char*)(r0)+off)`: the macros' unaligned-safe 32-bit load.
inline fn load32(r0: anytype, comptime off: usize) c_uint {
    const p: *align(1) const c_uint = @ptrFromInt(@intFromPtr(r0) + off);
    return p.*;
}

/// `*(uint*)((char*)(r0)+off) = value`.
inline fn store32(r0: anytype, comptime off: usize, value: c_uint) void {
    const p: *align(1) c_uint = @ptrFromInt(@intFromPtr(r0) + off);
    p.* = value;
}

/// gte_SetRotMatrix: the rotation part of a MATRIX into control registers 0-4.
pub inline fn SetRotMatrix(r0: anytype) void {
    CTC2(load32(r0, 0), 0);
    CTC2(load32(r0, 4), 1);
    CTC2(load32(r0, 8), 2);
    CTC2(load32(r0, 12), 3);
    CTC2(load32(r0, 16), 4);
}

/// gte_SetTransMatrix: a MATRIX's translation `t` into control registers 5-7.
pub inline fn SetTransMatrix(r0: anytype) void {
    CTC2(load32(r0, 20), 5);
    CTC2(load32(r0, 24), 6);
    CTC2(load32(r0, 28), 7);
}

/// gte_ldv0: VXY0, VZ0 from an SVECTOR.
pub inline fn ldv0(r0: anytype) void {
    MTC2(load32(r0, 0), 0);
    MTC2(load32(r0, 4), 1);
}

/// gte_rtv0tr2 (vs_inline_c.h): gte_rtv0tr on the PC.
pub inline fn rtv0tr2() void {
    _ = doCOP2(0x0480012);
}

/// gte_stlvnl: MAC1-3 (data registers 25-27) into three 32-bit words.
pub inline fn stlvnl(r0: anytype) void {
    store32(r0, 0, MFC2(25));
    store32(r0, 4, MFC2(26));
    store32(r0, 8, MFC2(27));
}

/// gte_rtps: perspective transformation of V0.
pub inline fn rtps() void {
    _ = doCOP2(0x0180001);
}

/// gte_rtps2 (vs_inline_c.h): gte_rtps on the PC.
pub inline fn rtps2() void {
    rtps();
}

/// gte_rtpt: perspective transformation of V0-V2.
pub inline fn rtpt() void {
    _ = doCOP2(0x0280030);
}

/// gte_nclip: normal clipping (the sign of the screen triangle's area into MAC0).
pub inline fn nclip() void {
    _ = doCOP2(0x01400006);
}

/// gte_avsz3: the average of SZ1-SZ3 into OTZ.
pub inline fn avsz3() void {
    _ = doCOP2(0x0158002D);
}

/// gte_stsxy (USE_PGXP=0): SXY2 (data register 14) into a 32-bit word.
pub inline fn stsxy(r0: anytype) void {
    store32(r0, 0, MFC2(14));
}

/// gte_stotz: OTZ (data register 7) into a 32-bit word.
pub inline fn stotz(r0: anytype) void {
    store32(r0, 0, MFC2(7));
}

/// gte_stszotz: SZ3 (data register 19) >> 2 into a 32-bit word.
pub inline fn stszotz(r0: anytype) void {
    store32(r0, 0, MFC2(19) >> 2);
}

/// gte_stopz: MAC0 (data register 24) into a 32-bit word.
pub inline fn stopz(r0: anytype) void {
    store32(r0, 0, MFC2(24));
}

/// gte_ldsxy3: SXY0-SXY2 through three pointers (PsyCross's takes pointers;
/// the PS1 macro takes values), loaded in the macro's order 12, 14, 13.
pub inline fn ldsxy3(r0: anytype, r1: anytype, r2: anytype) void {
    MTC2(load32(r0, 0), 12);
    MTC2(load32(r2, 0), 14);
    MTC2(load32(r1, 0), 13);
}

/// gte_nclip2 (vs_inline_c.h): gte_nclip on the PC.
pub inline fn nclip2() void {
    nclip();
}

/// gte_zrtr (vs_inline_c.h): the translation (control registers 5-7) zeroed.
pub inline fn zrtr() void {
    CTC2(0, 5);
    CTC2(0, 6);
    CTC2(0, 7);
}

// The GTE's maths as values (pc/src/gte_value_core.h, gte_value.h): a view and a vector in, the registers'
// results out, on a private register set (the game's registers are not read or changed).

/// vs_gte_screen: OFX and OFY as the registers hold them (16.16), H, DQA, DQB.
pub const Screen = extern struct { ofx: c_int, ofy: c_int, h: c_int, dqa: c_int, dqb: c_int };

/// vs_gte_view: rotation, translation, projection.
pub const View = extern struct { rot: [3][3]i16, t: [3]c_int, screen: Screen };

/// vs_gte_result: the registers an operation writes (the others are zero).
pub const Result = extern struct {
    sxy: c_int,
    sx: i16,
    sy: i16,
    sz: c_uint,
    otz: c_uint,
    ir0: i16,
    ir: [3]i16,
    mac: [4]c_int,
    flag: c_uint,
};

const RTPS: c_int = 0x0180001;
const RTV0TR: c_int = 0x0480012;
const RTV0: c_int = 0x0486012;

extern fn vs_gte_run(op: c_int, view: *const View, v: *const [3]i16, caller: ?*const anyopaque) callconv(.c) Result;
extern fn vs_gte_screen_current() callconv(.c) Screen;

/// For a transform or a rotation, which do not project.
pub const no_screen: Screen = .{ .ofx = 0, .ofy = 0, .h = 0, .dqa = 0, .dqb = 0 };

/// The projection the game has set so far (SetGeomOffset, SetGeomScreen).
pub fn screenCurrent() Screen {
    return vs_gte_screen_current();
}

/// The PS1 MATRIX layout: the rotation, a pad halfword, the translation at +20.
const Matrix = extern struct { m: [3][3]i16, pad: i16, t: [3]c_int };

/// SetRotMatrix and SetTransMatrix of a MATRIX (rotation at +0, translation at +20).
pub fn viewOf(m: anytype, screen: Screen) View {
    var view: View = undefined;
    const mat: *align(1) const Matrix = @ptrCast(m);
    view.rot = mat.m;
    view.t = mat.t;
    view.screen = screen;
    return view;
}

/// SetRotMatrix of a MATRIX with the translation zero (gte_zrtr).
pub fn viewRotation(m: anytype, screen: Screen) View {
    var view = viewOf(m, screen);
    view.t = .{ 0, 0, 0 };
    return view;
}

/// RotTrans: the vector rotated and translated (MAC1-3).
pub inline fn transform(view: *const View, vec: anytype) Result {
    return vs_gte_run(RTV0TR, view, @ptrCast(vec), @ptrFromInt(@returnAddress()));
}

/// ApplyRotMatrix, ApplyMatrix: the vector rotated (MAC1-3, IR1-3).
pub inline fn rotate(view: *const View, vec: anytype) Result {
    return vs_gte_run(RTV0, view, @ptrCast(vec), @ptrFromInt(@returnAddress()));
}

/// RotTransPers: the vector projected (sxy, sz, otz, ir0).
pub inline fn project(view: *const View, vec: anytype) Result {
    return vs_gte_run(RTPS, view, @ptrCast(vec), @ptrFromInt(@returnAddress()));
}

/// RotTrans stored as a vector (gte_stlvnl): MAC1-3, the flags dropped.
pub inline fn transformTo(out: anytype, view: *const View, vec: anytype) void {
    const r = vs_gte_run(RTV0TR, view, @ptrCast(vec), @ptrFromInt(@returnAddress()));
    storeVector(out, r);
}

/// ApplyMatrix, ApplyRotMatrix stored as a vector.
pub inline fn rotateTo(out: anytype, view: *const View, vec: anytype) void {
    const r = vs_gte_run(RTV0, view, @ptrCast(vec), @ptrFromInt(@returnAddress()));
    storeVector(out, r);
}

fn storeVector(out: anytype, r: Result) void {
    const v: *align(1) [3]c_int = @ptrCast(out);
    v.* = r.mac[1..4].*;
}
