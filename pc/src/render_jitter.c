#define _POSIX_C_SOURCE 200809L
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "render_jitter.h"

static struct {
    int on; /* -1 unread */
    uint64_t state;
    unsigned max_us, per_mille;
    unsigned long long calls[PC_JITTER_POINTS], sleeps[PC_JITTER_POINTS], slept_us;
} j __attribute__((section(".data.rood_host"))) = { -1 }; /* host state: not in snapshots */

static unsigned next(void)
{
    j.state ^= j.state << 13, j.state ^= j.state >> 7, j.state ^= j.state << 17;
    return (unsigned)(j.state >> 11);
}
static int enabled(void)
{
    if (j.on < 0) {
        const char* v = getenv("ROOD_RENDER_JITTER");
        j.on = v != NULL;
        if (v) {
            /* seed[:max_us[:per_mille]] */
            unsigned long long field[3] = { 0, 0, 0 };
            int k = 0;
            for (const char* p = v; *p && k < 3; p++) {
                if (*p == ':')
                    ++k;
                else if (*p >= '0' && *p <= '9')
                    field[k] = field[k] * 10 + (unsigned)(*p - '0');
            }
            j.state = field[0] * 0x9e3779b97f4a7c15ull + 0x1234567ull;
            j.max_us = k >= 1 ? (unsigned)field[1] : 3000, j.per_mille = k >= 2 ? (unsigned)field[2] : 300;
        }
    }
    return j.on;
}
void pc_jitter(int point)
{
    if (!enabled() || point < 0 || point >= PC_JITTER_POINTS)
        return;
    ++j.calls[point];
    if (next() % 1000 >= j.per_mille)
        return;
    unsigned us = j.max_us ? next() % j.max_us + 1 : 0;
    struct timespec t = { 0, (long)us * 1000L };
    nanosleep(&t, NULL);
    ++j.sleeps[point];
    j.slept_us += us;
}
int pc_jitter_json(char* out, int size)
{
    if (!enabled())
        return 0;
    unsigned long long calls = 0, sleeps = 0;
    for (int i = 0; i < PC_JITTER_POINTS; i++)
        calls += j.calls[i], sleeps += j.sleeps[i];
    return snprintf(out, (size_t)size, ",\"jitter\":{\"calls\":%llu,\"sleeps\":%llu,\"slept_us\":%llu}", calls,
        sleeps, j.slept_us);
}
