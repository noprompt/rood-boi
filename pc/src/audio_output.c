/* Host audio output and the audio thread.
 *
 * With an audio device (SDL: PipeWire, PulseAudio or ALSA, whichever it finds) the sound runs on its
 * own thread, clocked by the device: whenever the stream holds less than audio_latency_ms of samples
 * the thread runs one slice (a tick of the game's sound driver at about 240 Hz, the register sync and
 * a tick's worth of software SPU output, pc_audio_slice) and queues it. The game thread never waits on
 * it for samples, so a long or hitched game frame no longer starves the sound, and a stalled sound
 * never delays a frame. The two share the driver's state and the SPU through one recursive lock
 * (pc_sound_lock): the audio thread holds it for a slice; the game thread holds it for each SDK
 * sound call, around each sound command (the driver's own DisableEvent/EnableEvent of its timer
 * event, which on the PS1 masked its interrupt: pc_audio_enable_tick) and around a save state or
 * rewind; a hold is bounded by one slice (well under a millisecond), so it is a lock and not a queue.
 *
 * Without a device, with ROOD_AUDIO=none, or with ROOD_AUDIO=wav:<path> (a recording: tests) there is
 * no thread: the sound is clocked by the game's fields (pc_audio_frame: four slices per field on the
 * game thread), so the driver's state, which game logic reads, depends only on the frame count and a
 * headless run is deterministic. Recorded frames and the field-clocked sound are what the compare
 * and probe tools see. */
#define _GNU_SOURCE
#include "audio.h"
#include <SDL3/SDL.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { BLOCK = 256 };
static FILE* wav;
static uint32_t wav_frames;

/* Settings audio_latency_ms (project_settings.cpp): how much sound the audio thread keeps queued
 * ahead of the device; read every slice, so a change applies at once. More rides out a longer stall of
 * the audio thread (a loaded machine) and adds that much delay to what is heard. */
extern int pc_audio_latency_ms __attribute__((weak));
static int latency_frames(void)
{
    int ms = &pc_audio_latency_ms ? pc_audio_latency_ms : 50;
    return (ms < 10 ? 10 : ms > 500 ? 500 : ms) * 44100 / 1000;
}

/* The lock between the game thread and the audio thread (above): recursive, since the driver's
 * callbacks run SDK calls (SpuWrite) under the slice's hold. */
static pthread_mutex_t sound_mutex;
static pthread_once_t sound_once = PTHREAD_ONCE_INIT;
static void sound_init(void)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&sound_mutex, &attr);
    pthread_mutexattr_destroy(&attr);
}
void pc_sound_lock(void)
{
    pthread_once(&sound_once, sound_init);
    pthread_mutex_lock(&sound_mutex);
}
void pc_sound_unlock(void) { pthread_mutex_unlock(&sound_mutex); }
/* The game thread's mask of the sound driver's timer (the game's DisableEvent of its sound event,
 * until its EnableEvent): one hold, however often it is masked. (Not a state unit's: a save state
 * must not restore it.) */
static int masked;
void pc_sound_mask(void)
{
    pc_sound_lock();
    if (masked)
        pc_sound_unlock();
    masked = 1;
}
void pc_sound_unmask(void)
{
    if (masked) {
        masked = 0;
        pc_sound_unlock();
    }
}

/* Master volume (settings master_volume 0..100, System > Audio): a gain on
 * what leaves the game (the device stream and a ROOD_AUDIO=wav recording),
 * (volume / 100)^2 so equal steps sound about even. Changes ramp over 20 ms
 * (no clicks). At 100 the samples pass untouched (bit-identical). */
enum { GAIN_RAMP = 882 };
static int master_volume = 100;
int pc_master_volume_get(void) { return __atomic_load_n(&master_volume, __ATOMIC_RELAXED); }
void pc_master_volume_set(int volume)
{
    __atomic_store_n(&master_volume, volume < 0 ? 0 : volume > 100 ? 100 : volume, __ATOMIC_RELAXED);
}
static float duck = 1.0f; /* pc_audio_output_duck */
void pc_audio_output_duck(float gain)
{
    __atomic_store(&duck, &gain, __ATOMIC_RELAXED);
}
static float master_target(void)
{
    float v = pc_master_volume_get() / 100.0f, d;
    __atomic_load(&duck, &d, __ATOMIC_RELAXED);
    return v * v * (d < 0 ? 0 : d > 1 ? 1 : d);
}
/* Scales `count` stereo frames in place; *gain is the stream's current gain
 * (one per consumer), moved toward the target per frame. A stream
 * starts at the target (GAIN_UNSET: no samples yet), so a saved low volume
 * never begins with a ramp down from full, whichever of the settings and the
 * audio comes up first. */
#define GAIN_UNSET -1.0f
static void master_gain(short* frames, int count, float* gain)
{
    float target = master_target();
    if (*gain == GAIN_UNSET)
        *gain = target;
    if (*gain == 1.0f && target == 1.0f)
        return;
    const float step = 1.0f / GAIN_RAMP;
    for (int i = 0; i < count; ++i) {
        if (*gain < target)
            *gain = *gain + step < target ? *gain + step : target;
        else if (*gain > target)
            *gain = *gain - step > target ? *gain - step : target;
        for (int c = 0; c < 2; ++c) {
            float v = frames[i * 2 + c] * *gain;
            frames[i * 2 + c] = (short)(v > 32767.0f ? 32767 : v < -32768.0f ? -32768 : (int)(v < 0 ? v - 0.5f : v + 0.5f));
        }
    }
}
static float device_gain = GAIN_UNSET, wav_gain = GAIN_UNSET; /* each its consumer thread's */
static float device_gain_seen = GAIN_UNSET;                    /* device_gain, published for the RPC */
/* RPC (system): the gain now (after the ramp): the recording's, else the device stream's (the target before
 * any sample went out). */
float pc_master_gain(void)
{
    float g;
    if (wav)
        g = wav_gain; /* the game thread's own */
    else
        __atomic_load(&device_gain_seen, &g, __ATOMIC_RELAXED);
    return g == GAIN_UNSET ? master_target() : g;
}
/* RPC (system): frames recorded so far (ROOD_AUDIO=wav; tests find a moment in the file). */
unsigned pc_audio_output_recorded(void) { return wav_frames; }

static void wav_header(void)
{
    uint32_t bytes = wav_frames * 4;
    uint32_t header[11] = { 0x46464952, 36 + bytes, 0x45564157, 0x20746d66, 16,
        0x00020001, 44100, 44100 * 4, 0x00100004, 0x61746164, bytes };
    fseek(wav, 0, SEEK_SET);
    fwrite(header, 4, 11, wav);
    fseek(wav, 0, SEEK_END);
    fflush(wav);
}

/* photo.cpp: a photo mode render runs the game from its frozen moment: nothing it plays is heard. */
extern int pc_photo_rendering __attribute__((weak));
/* The field-clocked sound (pc_audio_frame): a recording keeps every frame, otherwise there is nowhere
 * for them to go. */
void pc_audio_output_push(const short* frames, int count)
{
    if ((&pc_photo_rendering && pc_photo_rendering) || !wav)
        return;
    if (wav_gain != 1.0f || master_target() != 1.0f) { /* (also the first block: GAIN_UNSET) */
        short scaled[BLOCK * 2];
        for (int done = 0; done < count; done += BLOCK) {
            int n = count - done < BLOCK ? count - done : BLOCK;
            memcpy(scaled, frames + done * 2, (size_t)n * 4);
            master_gain(scaled, n, &wav_gain);
            fwrite(scaled, 4, n, wav);
        }
    } else
        fwrite(frames, 4, count, wav);
    wav_frames += count;
    if (wav_frames % 44100 < (uint32_t)count)
        wav_header();
}

/* ---- the audio thread ---- */
static SDL_AudioStream* stream;
static int device_clocked; /* the thread runs the sound (set before it starts) */
static int paused;         /* the photo mode's stop: no slices, the device plays silence */
int pc_audio_device_clocked(void) { return device_clocked; }
void pc_audio_pause(int on) { __atomic_store_n(&paused, on, __ATOMIC_RELAXED); }

/* The driver ticks at the field rate times four: 44100 * 1001 / 240000 = 183.93 frames each, the
 * fraction carried so the output rate matches what the sound card consumes. */
static int slice_frames(void)
{
    static unsigned remainder;
    remainder += 44100 * 1001;
    int frames = (int)(remainder / 240000);
    remainder %= 240000;
    return frames;
}

static void* audio_thread(void* unused)
{
    (void)unused;
    short buffer[256 * 2]; /* a slice is 184 frames */
    int primed = 0, underruns = 0;
    for (;;) {
        if (__atomic_load_n(&paused, __ATOMIC_RELAXED)) {
            primed = 0;
            SDL_Delay(5);
            continue;
        }
        int queued = SDL_GetAudioStreamQueued(stream) / 4;
        if (queued >= latency_frames()) {
            SDL_Delay(1);
            continue;
        }
        if (primed && queued == 0 && underruns++ < 20)
            fprintf(stderr, "[audio] underrun: the audio thread did not keep up (raise audio_latency_ms)\n");
        int frames = slice_frames();
        pc_audio_slice(buffer, frames);
        master_gain(buffer, frames, &device_gain);
        __atomic_store(&device_gain_seen, &device_gain, __ATOMIC_RELAXED);
        if (!SDL_PutAudioStreamData(stream, buffer, frames * 4)) {
            fprintf(stderr, "[audio] SDL audio write failed (%s); audio stopped\n", SDL_GetError());
            return NULL; /* the game goes on, silent */
        }
        primed = 1;
    }
}

void pc_audio_output_start(void)
{
    const char* mode = getenv("ROOD_AUDIO");
    if (mode && !strcmp(mode, "none"))
        return;
    if (mode && !strncmp(mode, "wav:", 4)) {
        wav = fopen(mode + 4, "wb");
        if (wav)
            wav_header();
        fprintf(stderr, "[audio] recording output to %s\n", mode + 4);
        return;
    }
    SDL_SetAppMetadata("Vagrant Story (rood-boi)", NULL, "rood-boi");
    SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
    SDL_SetHint(SDL_HINT_AUDIO_DEVICE_STREAM_NAME, "game");
    SDL_SetHint(SDL_HINT_AUDIO_DEVICE_STREAM_ROLE, "Game");
    if (!SDL_InitSubSystem(SDL_INIT_AUDIO)) {
        fprintf(stderr, "[audio] no audio output (%s); running silently\n", SDL_GetError());
        return;
    }
    const SDL_AudioSpec spec = { SDL_AUDIO_S16LE, 2, 44100 };
    stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);
    if (!stream) {
        fprintf(stderr, "[audio] cannot open an audio device (%s); running silently\n", SDL_GetError());
        return;
    }
    pthread_t thread;
    device_clocked = 1;
    if (pthread_create(&thread, NULL, audio_thread, NULL)) {
        device_clocked = 0;
        fprintf(stderr, "[audio] cannot start the audio thread; running silently\n");
        return;
    }
    pthread_detach(thread);
    SDL_ResumeAudioStreamDevice(stream);
    fprintf(stderr, "[audio] %s output started (44.1 kHz stereo, audio thread, %d ms ahead)\n",
        SDL_GetCurrentAudioDriver(), latency_frames() * 1000 / 44100);
}
