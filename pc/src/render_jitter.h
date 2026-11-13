/* The R4 proof harness (T1): seeded timing noise injected at the points where the game thread hands work to the
 * renderer side (the present service and the fences). ROOD_RENDER_JITTER=seed[:max_us[:per_mille]]:
 * at each point, with probability per_mille/1000 the caller sleeps up to max_us (the renderer being late). The renderer side is inline today, so
 * nothing may change; once it is a thread, the same runs are the gate: state, stream and frames must not depend on timing.
 * Without the variable every call is a no-op. */
#ifndef PC_RENDER_JITTER_H
#define PC_RENDER_JITTER_H
enum { PC_JITTER_PRESENT, PC_JITTER_FRACTION, PC_JITTER_FENCE, PC_JITTER_POINTS };
/* Maybe delay here (the renderer side being slow). */
void pc_jitter(int point);
/* The counters, as JSON members for RPC vram_stream: appended as ,"jitter":{...}; returns the bytes written. */
int pc_jitter_json(char* out, int size);
#endif
