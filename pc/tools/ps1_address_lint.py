#!/usr/bin/env python3
"""The game's PS1 ties, counted: the numbers may only go down.

    python3 pc/tools/ps1_address_lint.py            fail if a count rose above the baseline
    python3 pc/tools/ps1_address_lint.py --update   lower the baseline to today's counts
    python3 pc/tools/ps1_address_lint.py --raise    accept a rise too (say why in the commit)
    python3 pc/tools/ps1_address_lint.py --where RULE   each hit of a rule

Counts PS1 addresses, unnamed symbols and guest-pointer helpers in code (not
comments) under pc/src and game/, so the move off the PS1 is a number the
tools hold. The idea and the address patterns follow VS-NativePort's
tools/lint/native_boundary.py (origin/imp/01-ma04-gates, 6c8ac0b9, CC0); the
ratchet is ours, since this tree starts with thousands of hits.
Baseline: pc/tools/ps1_address_baseline.json.
"""
import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASELINE = ROOT / "pc/tools/ps1_address_baseline.json"
C_SUFFIXES = {".c", ".h", ".inc", ".cpp", ".hpp"}
TREES = [("pc/src", C_SUFFIXES), ("game", C_SUFFIXES | {".zig"})]
SKIP = ("pc/src/third_party/",)
RULES = {
    "ps1_address": re.compile(r"\b0[xX](?:80|[aA]0)[0-9a-fA-F]{6}\b"),
    "scratchpad": re.compile(r"\b0[xX]1[fF]80[0-9a-fA-F]{4}\b|\bgetScratchAddr\b"),
    "unnamed_symbol": re.compile(r"\b(?:D|func)_80[0-9a-fA-F]{6}\b"),
    "guest_pointer_field": re.compile(r"\bpsx_ptr\("),
    "guest_pointer_access": re.compile(r"\bpsx_(?:get|set|set_raw|copy|add|postinc|load|store)\("),
    "address_as_integer": re.compile(r"\bpsx_to_(?:int|ptr)\(|\bpsx\.(?:addr|rawOf)\("),
    "zig_raw_memory": re.compile(r"\bpsx\.byteAt\(|@ptrFromInt\("),
    # The GTE as a global register machine (PS1_Ties.md T7): the game's code only.
    "gte_state_machine": re.compile(r"\bgte_[A-Za-z0-9_]+\("),
    # The libgte calls that run on the same registers underneath.
    "gte_sdk_calls": re.compile(r"\b(?:SetRotMatrix|SetTransMatrix|ApplyRotMatrix|ApplyMatrix|RotTransPers[34]?|"
                                r"RotTrans|RotTransSV|RotAverage4|RotAverageNclip4|SetGeomOffset|SetGeomScreen)\("),
}
# Rules that count only under a path (the others count in every tree).
ONLY_UNDER = {"gte_state_machine": "pc/src/game/", "gte_sdk_calls": "pc/src/game/"}
COMMENTS = re.compile(r'"(?:\\.|[^"\\\n])*"|/\*.*?\*/|//[^\n]*', re.S)


def strip_comments(text):
    """Comments blanked (their line breaks kept), strings left alone."""
    def blank(match):
        token = match.group(0)
        return token if token.startswith('"') else "\n" * token.count("\n")
    return COMMENTS.sub(blank, text)


def sources():
    for tree, suffixes in TREES:
        for path in sorted((ROOT / tree).rglob("*")):
            name = path.relative_to(ROOT).as_posix()
            if path.suffix in suffixes and path.is_file() and not name.startswith(SKIP):
                yield name, path


def scan():
    """{rule: count}, {rule: [(file, line, text)]}."""
    counts, hits = dict.fromkeys(RULES, 0), {rule: [] for rule in RULES}
    for name, path in sources():
        code = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
        for number, line in enumerate(code.splitlines(), 1):
            for rule, pattern in RULES.items():
                if not name.startswith(ONLY_UNDER.get(rule, "")):
                    continue
                found = pattern.findall(line)
                if found:
                    counts[rule] += len(found)
                    hits[rule].append((name, number, line.strip()[:110]))
    return counts, hits


def compare(counts, baseline):
    """The rules that rose, and those that fell, as {rule: (baseline, now)}."""
    rose = {r: (baseline.get(r, 0), n) for r, n in counts.items() if n > baseline.get(r, 0)}
    fell = {r: (baseline.get(r, 0), n) for r, n in counts.items() if n < baseline.get(r, 0)}
    return rose, fell


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--raise", dest="accept_rise", action="store_true")
    parser.add_argument("--where", choices=sorted(RULES))
    args = parser.parse_args()
    counts, hits = scan()
    if args.where:
        for name, number, text in hits[args.where]:
            print(f"{name}:{number}: {text}")
        return 0
    baseline = json.loads(BASELINE.read_text()) if BASELINE.exists() else {}
    rose, fell = compare(counts, baseline)
    if args.accept_rise or (args.update and not rose):
        BASELINE.write_text(json.dumps(counts, indent=1) + "\n")
    for rule, count in counts.items():
        mark = " (rose)" if rule in rose else " (fell)" if rule in fell else ""
        print(f"{rule:22} {count:6}{mark}")
    if rose and not args.accept_rise:
        for rule, (before, now) in rose.items():
            print(f"FAIL: {rule} rose from {before} to {now}; --where {rule} lists them")
        return 1
    if fell and not args.update:
        print("fell: lower the baseline with --update")
    return 0


if __name__ == "__main__":
    sys.exit(main())
