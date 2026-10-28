//! Camera-mode dispatch for battle (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B9FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the camera routine for `_cameraMode` 3..6 and reports whether one ran.
pub fn func_8007B9FC() callconv(.c) c_int {
    switch (v.g._cameraMode().*) {
        3 => {
            c.func_8007B834();
            return 1;
        },
        4 => {
            c.func_8007B884();
            return 1;
        },
        5 => {
            c.func_8007B908();
            return 1;
        },
        6 => {
            c.func_8007B938();
            return 1;
        },
        else => return 0,
    }
}
