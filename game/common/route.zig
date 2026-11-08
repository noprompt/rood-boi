//! Exports of the owned functions under the original names, so C reaches the Zig directly.
const std = @import("std");

/// The exports of one subsystem's routes. `routes` is either the original
/// names (the Zig function has the same name in `Impl`) or ownership.zig's
/// `routesOf(...)`: each original `name` is exported from the Zig function at
/// `zig` (PORTING.md §16).
///
/// The build's `reload_mode` (the root's `reload_mode` declaration):
///   0  (absent) the static build: each function is exported as `name`.
///   1  the development host: `name` is a trampoline through a slot of the reloadable library
///      (ownership.py routing_source), so only the signature is exported, for the loader to check;
///      a resident route is exported as `name` itself.
///   2  the reloadable library: `name__candidate` and its signature; a resident route is left out.
pub fn exportAll(comptime subsystem: u8, comptime routes: anytype, comptime Impl: type) void {
    _ = subsystem;
    // Resolving each dotted path is comptime work that grows with the routes
    // (the default 1000 backward branches ran out at five pipeline routes).
    @setEvalBranchQuota(2000 + 1000 * routes.len);
    for (routes) |route| {
        const is_route = @typeInfo(@TypeOf(route)) == .@"struct";
        const name: []const u8 = if (is_route) route.name else route;
        const zig_path: []const u8 = if (is_route) route.zig else route;
        const resident = is_route and route.resident;
        // The declaration at the dotted path ("score.updateEnemyKills").
        const f = comptime blk: {
            var space = Impl;
            var rest = zig_path;
            while (std.mem.indexOfScalar(u8, rest, '.')) |dot| {
                space = @field(space, rest[0..dot]);
                rest = rest[dot + 1 ..];
            }
            break :blk @field(space, rest);
        };
        const root = @import("root");
        const mode = if (@hasDecl(root, "reload_mode")) root.reload_mode else 0;
        if (mode == 0 or (mode == 1 and resident)) {
            @export(&f, .{ .name = name });
        } else if (!resident) {
            const Signature = struct {
                const text = (@typeName(@TypeOf(f)) ++ "\x00").*;
            };
            @export(&Signature.text, .{ .name = name ++ (if (mode == 2) "__candidate_abi" else "__owned_abi") });
            if (mode == 2) @export(&f, .{ .name = name ++ "__candidate" });
        }
    }
}
