#!/usr/bin/env bash
# Verify the tree in one of two lanes, one line per step.
#
#   QUICK (the default; before each publish, target under 10 minutes): the
#   builds, then the suites the change since BASE can affect (run.py --changed
#   --quick; pc/tests/affected.toml): on Vulkan with ctest; the CPU-safe ones
#   on the null renderer with null_backend_smoke; on OpenGL a sanity subset
#   (boot, a room, the opening, the goldens, the title) plus what GL's own
#   files select. Long suites (soak, the charge skip, zig_diff, the story
#   viewer) only when the change touches them; zig_diff then only on the specs
#   the change affects (pc/tools/zig_diff_select.py), unless its shared
#   infrastructure changed.
#   FULL (--full; once a day, and before bigger releases): every suite on the
#   null renderer, Vulkan and OpenGL, long suites included, and the Windows build.
#
#   Policy: quick before each publish; full once a day; when the daily full run
#   finds a break, fix it or revert the merge that made it (the merge log names
#   the branch).
#
#   pc/tools/verify.sh                   quick, against BASE: on main the last
#                                        published snapshot (the public branch),
#                                        elsewhere main
#   pc/tools/verify.sh --changed [BASE]  quick, against BASE (default main)
#   pc/tools/verify.sh --full            full
#   pc/tools/verify.sh --windows         also the Windows cross build in quick
#   pc/tools/verify.sh --no-windows      skip it in full
#   pc/tools/verify.sh -- ARGS...        more run.py options for every suite
#                                        (e.g. -- -j 4 --gpu-jobs 3)
#
# Both lanes build 32-bit (the boot and the battle probe) and 64-bit; the
# suites run on 64-bit, what ships and what the oracle checks. Builds hold
# $ROOD_BUILD_LOCK and test suites $ROOD_HEAVY_LOCK (flock; without a build
# lock both take the heavy one), so one session's build runs beside another's
# tests while the GPU suites never overlap. The Windows build comes last, at
# nice 19. Logs: pc/build/verify/<step>.log; suite outputs in
# pc/build/verify/<suite run>/. Exit status: the number of failed steps.
set -u
cd "$(dirname "$0")/../.."
lane=quick base= windows= extra=()
while [ $# -gt 0 ]; do
    case "$1" in
        --changed)
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then base=$2; shift; else base=main; fi ;;
        --quick) lane=quick ;;
        --full) lane=full ;;
        --gl) ;;  # kept for old command lines: the full lane always runs OpenGL, quick its sanity subset
        --no-windows) windows=0 ;;
        --windows) windows=1 ;;
        --) shift; extra=("$@"); break ;;
        -h|--help) sed -n '2,/^set -u$/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
        *) echo "verify.sh: unknown option $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done
if [ $lane = full ] && [ -n "$base" ]; then
    echo "verify.sh: --full runs every suite; --changed is for the quick lane" >&2; exit 2
fi
if [ $lane = quick ] && [ -z "$base" ]; then
    # On main, what is not yet published; on a branch, what it changed.
    if [ "$(git symbolic-ref --short -q HEAD 2>/dev/null)" = main ] && git rev-parse -q --verify public >/dev/null 2>&1; then
        base=public
    else
        base=main
    fi
fi
# Windows: on for the full lane, off for quick unless asked (low priority).
[ -z "$windows" ] && { [ $lane = full ] && windows=1 || windows=0; }
out=pc/build/verify
mkdir -p "$out"
failed=0 start_all=$SECONDS
null_suites=(null_backend_smoke shadow_battle_smoke ownership_smoke battle_corpus_candidate zig_hotswap_smoke
             trial_corpus classic_parity)
select=()
if [ $lane = quick ]; then
    select=(--changed "$base" --quick)
    echo "lane: quick, the change since $base ($(git rev-parse --short "$base" 2>/dev/null || echo '?'))"
    python3 pc/tests/affected.py "$base" --quick-summary
else
    echo "lane: full, every suite on null, Vulkan and OpenGL"
fi

step() {  # step build|test|cpu NAME COMMAND...: run it (under its lock), print one line
    local kind=$1 name=$2; shift 2
    local log="$out/$name.log" t=$SECONDS status
    local lock=${ROOD_HEAVY_LOCK:-}
    [ "$kind" = build ] && [ -n "${ROOD_BUILD_LOCK:-}" ] && lock=$ROOD_BUILD_LOCK
    [ "$kind" = cpu ] && lock= # genuine null backend: no GPU resource serialization
    python3 pc/tests/run.py --wait-cool  # only with a thermal pause set (run.py --thermal-pause)
    if [ -n "$lock" ]; then
        flock "$lock" "$@" > "$log" 2>&1
    else
        "$@" > "$log" 2>&1
    fi
    status=$?
    local summary
    summary=$(grep -E '^[0-9]+/[0-9]+ passed|^nothing to run|^--changed: |^Built ' "$log" | tail -1 \
        | sed -E 's|^Built [^:]*/([^/:]+):.*|built \1|')
    summary=${summary:-$(tail -1 "$log" | cut -c1-100)}
    if [ $status -eq 0 ]; then
        printf 'PASS  %-12s %5ds  %s\n' "$name" $((SECONDS - t)) "$summary"
    else
        failed=$((failed + 1))
        printf 'FAIL  %-12s %5ds  %s (%s)\n' "$name" $((SECONDS - t)) "$summary" "$log"
    fi
    return "$status"
}

step build build-32 python3 pc/tools/build_boot.py
step build battle-32 python3 pc/tools/build_boot.py --battle
if step build build-64 python3 pc/tools/build_boot.py --arch 64; then
    # End options before fixed suite names: --changed takes an optional BASE.
    step cpu suite-64null python3 pc/tests/run.py --arch 64 --renderer null --out "$out/t64null" \
        "${select[@]}" "${extra[@]}" -- "${null_suites[@]}"
    step test suite-64vk python3 pc/tests/run.py --arch 64 --renderer vulkan --out "$out/t64vk" "${select[@]}" "${extra[@]}"
    step test suite-64gl python3 pc/tests/run.py --arch 64 --renderer gl --out "$out/t64gl" "${select[@]}" "${extra[@]}"
else
    # Failed builds preserve old binaries; never test those as this build.
    printf 'SKIP  %-12s build-64 failed\n' suite-64null suite-64vk suite-64gl
fi
[ $windows = 1 ] && step build windows nice -n 19 python3 pc/tools/build_boot.py --target windows
printf '%s: %s in %ds\n' "$lane" "$([ $failed = 0 ] && echo 'all passed' || echo "$failed failed")" $((SECONDS - start_all))
exit $failed
