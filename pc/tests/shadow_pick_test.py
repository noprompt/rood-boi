#!/usr/bin/env python3
"""The renderer's shadow-caster pick against the lights module's own (T1 R4b-5): the two functions are cut out of their sources (pc/src/lights.cpp
pc_lights_shadow_pick with its hysteresis state, pc/src/present_header.c shadow_pick_renderer) into one program and run on the same random
frames (casters, importance, keys, repeated keys across frames, more casters than slots most of the time): every frame's choice must match. A
scene with more casters than slots is rare in the game's rooms, so this is where the sort and the hysteresis run.

    python3 pc/tests/shadow_pick_test.py
"""
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]


def cut(text, start, end_pattern):
    i = text.index(start)
    m = re.compile(end_pattern, re.M).search(text, i + len(start))
    return text[i:m.start()] + (m.group(0) if m.group(0).strip() == "}" else "")


def main():
    lights = (ROOT / "pc/src/lights.cpp").read_text()
    header = (ROOT / "pc/src/present_header.c").read_text()
    kept = lights[lights.index("struct Kept {"):lights.index("Kept* kept_for(int budget)")]
    kept_for = lights[lights.index("Kept* kept_for(int budget)"):]
    kept_for = kept_for[:kept_for.index("\n}\n") + 3]
    original = lights[lights.index('extern "C" void pc_lights_shadow_pick'):]
    original = original[:original.index("\n}\n") + 3]
    renderer = header[header.index("void pc_ph_lights_shadow_pick(int count, int* wants, int slots)\n{"):]
    renderer = renderer[:renderer.index("\n}\n") + 3]
    program = r'''
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#define PC_LIGHTS_MAX 1024
#define PC_PRESENT_GUARD(x)
struct { int out_count; unsigned long long out_keys[PC_LIGHTS_MAX]; float out_importance[PC_LIGHTS_MAX]; unsigned lights_frame; } pc_present_header_now_s;
#define PH pc_present_header_now_s
static unsigned pc_pick_chosen, pc_pick_max_casters;
namespace {
''' + kept + '''
''' + kept_for + '''
}
''' + original + '''
''' + renderer.replace("pc_present_header_now", "PH").replace("const pc_present_header* p = &PH;", "const auto* p = &PH;") + r'''
static unsigned long long hash_of(const std::string& s)
{
    if (s.empty())
        return 0;
    unsigned long long h = 1469598103934665603ull;
    for (unsigned char c : s)
        h = (h ^ c) * 1099511628211ull;
    return h;
}
int main(int argc, char** argv)
{
    int fixed = argc > 1 ? atoi(argv[1]) : 1; /* the slot count is constant in a run (the atlas's): each count is its own process, as each has its own state */
    srand(12345);
    int frames = 4000, bad = 0, chosen = 0;
    for (int f = 0; f < frames; f++) {
        int count = 1 + rand() % 24, slots = fixed;
        output_keys.clear(), output_importance.clear();
        std::vector<int> a(count), b;
        for (int i = 0; i < count; i++) {
            int id = rand() % 40; /* keys repeat across frames: the hysteresis */
            output_keys.push_back(rand() % 9 == 0 ? std::string() : "light:" + std::to_string(id));
            float imp = (rand() % 6 == 0) ? 1e30f : (float)(rand() % 100) / 10.0f; /* ties and a big one */
            output_importance.push_back(imp);
            a[i] = rand() % 3 != 0;
        }
        b = a;
        PH.out_count = count;
        for (int i = 0; i < count; i++)
            PH.out_keys[i] = hash_of(output_keys[i]), PH.out_importance[i] = output_importance[i];
        if (rand() % 3 == 0)
            ++lights_frame; /* some frames share the lights frame: the keys are kept once per frame */
        PH.lights_frame = lights_frame;
        int casters = 0;
        for (int w : a)
            casters += w != 0;
        pc_lights_shadow_pick(count, a.data(), slots);
        pc_ph_lights_shadow_pick(count, b.data(), slots);
        chosen += casters > slots;
        if (a != b && bad++ < 5)
            printf("frame %d differs (%d lights, %d slots)\n", f, count, slots);
    }
    printf("%d frames, %d with more casters than slots, %d differ\n", frames, chosen, bad);
    return bad != 0;
}
'''
    with tempfile.TemporaryDirectory() as d:
        src = pathlib.Path(d) / "pick.cpp"
        src.write_text(program)
        exe = pathlib.Path(d) / "pick"
        done = subprocess.run(["g++", "-std=c++17", "-O1", "-o", str(exe), str(src)], capture_output=True, text=True)
        if done.returncode:
            print(done.stderr[-2000:])
            return 2
        bad = 0
        for slots in (1, 2, 3, 4):
            run = subprocess.run([str(exe), str(slots)], capture_output=True, text=True)
            print(f"{slots} slots: {run.stdout.strip()}")
            bad |= run.returncode
        print("PASS: shadow_pick_test" if not bad else "FAIL: the renderer's pick differs from the lights module's")
        return bad


if __name__ == "__main__":
    sys.exit(main())
