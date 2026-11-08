/* The game's Zig (game/, Zig; pc/docs/Ownership.md): the host side.
 * This part: the owned objects' panic handler and the ABI check. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern void pc_unimplemented(const char* what) __attribute__((noreturn));
extern const uint32_t rood_game_abi; /* game/core/root.zig */
#define ROOD_GAME_ABI 1

/* game/common/panic.zig: a safety check failed in owned code (overflow,
 * bounds, unreachable, a null unwrap). */
__attribute__((noreturn)) void pc_zig_panic(const char* msg, size_t len, uintptr_t return_address)
{
    fprintf(stderr, "[zig] panic: %.*s (return address %#llx)\n", (int)len, msg,
        (unsigned long long)return_address);
    fflush(stderr);
    pc_unimplemented("owned code panicked (see the [zig] line)");
}

#ifndef ROOD_NO_OWNED /* built without Zig (build_boot.py): no owned objects yet */
__attribute__((constructor)) static void check_abi(void)
{
    if (rood_game_abi != ROOD_GAME_ABI) {
        fprintf(stderr, "[ownership] game_core ABI %u, the host expects %u\n", rood_game_abi, ROOD_GAME_ABI);
        abort();
    }
}
#endif
