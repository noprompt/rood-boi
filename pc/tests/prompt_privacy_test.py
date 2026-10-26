#!/usr/bin/env python3
"""prompt_privacy and model_client's last-line guard: no local path reaches an
external model. Fixtures are built at runtime (home, user, scratch names are
not written in this file); no network (urlopen is faked)."""
import json
import os
import pathlib
import re
import sys
import tempfile
import unittest.mock as mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pc/tools"))
import model_client  # noqa: E402
import prompt_privacy as pp  # noqa: E402

HOME = str(pathlib.Path.home())
USER = pp._user()
SCRATCH = "/" + "tmp" + "/claude" + "-" + str(os.getuid())  # built at runtime
MNT = "/" + "mnt" + "/tomb-3/rood-boi"
failures = []


def expect(cond, msg):
    if not cond:
        failures.append(msg)


def clean(text):
    out = pp.sanitise(text)
    left = pp.problems(out)
    expect(not left, f"still local ({left}): {out!r}")
    return out


def samples():
    wt = ROOT.name
    yield "zig error, worktree via /mnt", (
        f"{MNT}/worktrees/some-branch/pc/src/x.c:12:5: error: use of undeclared identifier 'y'\n"
        f"    int a = y;\n    ^\n", "pc/src/x.c:12:5: error")
    yield "zig error, worktree via home symlink", (
        f"{HOME}/git/noprompt/rood-boi/.claude/worktrees/some-branch/pc/tools/a.zig:3:9: error: expected ';'", "pc/tools/a.zig:3:9")
    yield "main checkout, real and home path", (f"{ROOT}/pc/src/z.c:1: x\n{HOME}/git/noprompt/rood-boi/pc/src/z.c:1: x", "pc/src/z.c:1: x")
    yield "a worktree that no longer exists", (f"{MNT}/worktrees/gone-branch/src/BATTLE/146C.c:99", "src/BATTLE/146C.c:99")
    yield "zig global cache via the mount", (
        f"error: unable to build: {MNT}/cache/zig/0.14.0/global-cache/o/ab12/cimport.zig:4:1: note", "<cache>/zig/0.14.0/global-cache/o/ab12/cimport.zig:4:1")
    yield "zig cache via the home symlink", (f"{HOME}/.cache/rood-boi/zig/0.14.0/lib/std/fmt.zig:9:1", "<cache>/zig/0.14.0/lib/std/fmt.zig:9:1")
    yield "unexpanded tilde cache", ("~/.cache/rood-boi/zig/lib/std.zig:1:1", "<cache>/zig/lib/std.zig:1:1")
    yield "agent scratch", (f"{SCRATCH}/-home-{USER}-git/abc/scratchpad/ref.c:12: warning", "ref.c:12: warning")
    yield "other mounts and runtime dirs", ("cannot open /" + "media/" + USER + "/usb/a.bin and /run/user/" + str(os.getuid()) + "/x.sock and /mnt/other/b.c:2",
                                          "<path>")
    yield "user name alone", (f"author {USER} wrote this", "<user>")
    yield "system header stays", ("/usr/include/stdio.h:1:10: note", "/usr/include/stdio.h:1:10")
    yield "relative paths stay", ("pc/tools/x.py and src/y.c", "pc/tools/x.py and src/y.c")


def test_sanitiser():
    for label, (text, want) in samples():
        out = clean(text)
        expect(want in out, f"{label}: expected {want!r} in {out!r}")
    host = pp._names()
    expect(not any(h.lower() in pp.sanitise(f"on host {h} at") .lower() for h in host), "names/hostname survived")
    # Idempotent.
    once = pp.sanitise(f"{MNT}/worktrees/b/pc/x.c:1 {HOME}/.cache/rood-boi/z")
    expect(pp.sanitise(once) == once, "sanitise is not idempotent")


def test_check_raises():
    for raw in (f"{MNT}/worktrees/b/x.c", f"{HOME}/x", f"{SCRATCH}/a", "/" + "mnt/x", "/" + "home/someone/x", f"user {USER}",
                f"claude-{os.getuid()}"):
        try:
            pp.check(raw)
            failures.append(f"check() accepted {raw!r}")
        except pp.Leak:
            pass


class FakeResponse:
    def __init__(self, body):
        self.body = body

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def read(self):
        return json.dumps(self.body).encode()


def test_guard():
    log = pathlib.Path(tempfile.mkdtemp(prefix="privlog-")) / "refusals.log"
    os.environ["ROOD_PRIVACY_LOG"] = str(log)
    os.environ["FAKE_KEY"] = "k"
    ep = model_client.Endpoint(api_key_env="FAKE_KEY")
    sent = []
    ok = {"choices": [{"message": {"content": "hi"}, "finish_reason": "stop"}], "usage": {}}

    def fake_urlopen(request, timeout=None):
        sent.append(request.data)
        return FakeResponse(ok)

    with mock.patch("urllib.request.urlopen", fake_urlopen):
        # The normal path sanitises: the compiler error goes out clean.
        model_client.call([{"role": "user", "content": f"fix {MNT}/worktrees/b/pc/x.c:3: error"}], "m", 100, ep)
        expect(len(sent) == 1 and b"pc/x.c:3" in sent[0] and not pp.problems(sent[0].decode()), f"clean send: {sent}")
        # A body that skipped the sanitiser (built by hand) is refused at the send.
        raw = {"model": "m", "messages": [{"role": "user", "content": f"see {MNT}/worktrees/b/x.c"}], "max_tokens": 5}
        before = len(sent)
        with mock.patch.object(model_client, "request_body", lambda *a, **k: raw):
            try:
                model_client.call([], "m", 5, ep)
                failures.append("call() sent a raw path")
            except model_client.Refused:
                pass
        # JSON-escaped slashes do not hide it.
        escaped = {"model": "m", "messages": [{"role": "user", "content": "/" + "home" + "/x"}], "max_tokens": 5}
        try:
            ep.guard(json.dumps(escaped).replace("/", "\\/").encode(), "t")
            failures.append("guard missed \\/-escaped path")
        except model_client.Refused:
            pass
        # Batch submit with a raw body is refused too (the bypass: request bodies built elsewhere).
        try:
            model_client.submit_batch([("1", raw)], "m", ep)
            failures.append("submit_batch sent a raw path")
        except model_client.Refused:
            pass
        # The user name, the scratch dir.
        for leak in (USER, "clau" + "de-" + str(1000), SCRATCH):
            try:
                ep.guard(json.dumps({"c": f"x {leak} y"}).encode(), "t")
                failures.append(f"guard missed {leak!r}")
            except model_client.Refused:
                pass
        expect(len(sent) == before, "a refused request left the machine")
        # A local endpoint is not refused (nothing leaves the machine).
        model_client.Endpoint(base_url="http://127.0.0.1:1/v1").guard(json.dumps(raw).encode(), "t")
    text = log.read_text() if log.exists() else ""
    expect("refused" in text, "refusals were not logged")
    expect(not re.search(r"/(mnt|home)/\w", text) and USER not in text and HOME not in text, f"the log holds a local path: {text!r}")


def main():
    test_sanitiser()
    test_check_raises()
    test_guard()
    for f in failures:
        print("FAIL:", f)
    print("prompt_privacy_test: " + ("FAILED" if failures else "passed"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
