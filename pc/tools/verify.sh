#!/usr/bin/env bash
# Verify the tree in one of two lanes, one line per step.
#
#   QUICK (the default; before each publish; at most 15 minutes, enforced): the
#   builds, then the suites the change since BASE can affect (run.py --changed
#   --quick; pc/tests/affected.toml), cut to a time budget per renderer by the
#   last run's times (run.py --budget: null 4, Vulkan 9, OpenGL 2 minutes;
#   ROOD_QUICK_BUDGET scales them); what does not fit is named as deferred and
#   left to the full lane. A suite list that still overruns is stopped at the
#   hard limit (ROOD_QUICK_LIMIT, default 20 minutes) and counts as a failure:
#   the quick lane never runs for hours. on Vulkan with ctest; the CPU-safe ones
#   on the null renderer with null_backend_smoke; on OpenGL a sanity subset
#   (boot, a room, the opening, the goldens, the title) plus what GL's own
#   files select. Long suites (soak, the charge skip, the story viewer) only
#   when the change touches them.
#   FULL (--full; once a day, and before bigger releases): every suite on the
#   null renderer, Vulkan and OpenGL, long suites included (the suites without a
#   game, CTest and lints, once: on Vulkan), and the Windows build.
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
# Both lanes build 64-bit only, what ships and what the oracle checks (the
# 32-bit build was retired 2026-11-06: no longer built, tested or kept up).
# Builds hold $ROOD_BUILD_LOCK and test suites $ROOD_HEAVY_LOCK (flock; without a build
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
null_suites=(null_backend_smoke ownership_smoke zig_hotswap_smoke classic_parity)
select=() budget_null=() budget_vk=() budget_gl=()
cap() {  # the words that stop a quick-lane step at the hard limit (what is left of it); nothing in full
    [ $lane = quick ] && echo timeout --kill-after=30 $(( ${ROOD_QUICK_LIMIT:-20} * 60 - (SECONDS - start_all) > 1 ?
        ${ROOD_QUICK_LIMIT:-20} * 60 - (SECONDS - start_all) : 1 ))
}
if [ $lane = quick ]; then
    select=(--changed "$base" --quick)
    scale=${ROOD_QUICK_BUDGET:-1}
    minutes() { awk "BEGIN { print $1 * $scale }"; }
    budget_null=(--budget "$(minutes 4)") budget_vk=(--budget "$(minutes 9)") budget_gl=(--budget "$(minutes 2)")

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

if step build build-64 python3 pc/tools/build_boot.py --arch 64; then
    # End options before fixed suite names: --changed takes an optional BASE.
    step cpu suite-64null $(cap) python3 pc/tests/run.py --arch 64 --renderer null --out "$out/t64null" \
        "${select[@]}" "${budget_null[@]}" "${extra[@]}" -- "${null_suites[@]}"
    step test suite-64vk $(cap) python3 pc/tests/run.py --arch 64 --renderer vulkan --out "$out/t64vk" \
        "${select[@]}" "${budget_vk[@]}" "${extra[@]}"
    # Full: the suites without a game (CTest, lints) ran on Vulkan; OpenGL runs the game's only.
    gl_only=(); [ $lane = full ] && gl_only=(--game-only)
    step test suite-64gl $(cap) python3 pc/tests/run.py --arch 64 --renderer gl --out "$out/t64gl" "${gl_only[@]}" \
        "${select[@]}" "${budget_gl[@]}" "${extra[@]}"
else
    # Failed builds preserve old binaries; never test those as this build.
    printf 'SKIP  %-12s build-64 failed\n' suite-64null suite-64vk suite-64gl
fi
[ $windows = 1 ] && step build windows nice -n 19 python3 pc/tools/build_boot.py --target windows
if [ $lane = quick ]; then
    deferred=$(cat "$out"/t64*/deferred.txt 2>/dev/null | sort -u | tr '\n' ' ')
    [ -n "$deferred" ] && echo "deferred to the full lane: $deferred"
    if [ $((SECONDS - start_all)) -gt $(( ${ROOD_QUICK_LIMIT:-20} * 60 )) ]; then
        echo "FAIL  quick-limit  the quick lane ran $(( (SECONDS - start_all) / 60 )) min, over its ${ROOD_QUICK_LIMIT:-20}"
        failed=$((failed + 1))
    fi
fi
printf '%s: %s in %ds\n' "$lane" "$([ $failed = 0 ] && echo 'all passed' || echo "$failed failed")" $((SECONDS - start_all))
exit $failed
