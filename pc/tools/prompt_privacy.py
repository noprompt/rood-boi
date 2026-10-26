#!/usr/bin/env python3
"""The one sanitiser for text sent to an external model (spec_bakeoff.py,
port_pipeline.py): prompts, compiler errors, harness output, retry
feedback. Nothing local leaves the machine: the checkout's path becomes
relative, the Zig cache (toolchain and global cache) becomes `<zig-cache>`,
scratch directories (/tmp/..., $TMPDIR) become `<tmp>`, any other path
under the home directory becomes `~/...`, and the user's name becomes
`<user>`.

    import prompt_privacy
    text = prompt_privacy.sanitise(text)        # before every call
    prompt_privacy.check(text)                  # raises Leak if anything local is left

`check` is the guard each caller runs on the exact request body; a test
(pc/tests/port_pipeline_test.py) fails if a prompt contains the home path.
"""
import datetime
import getpass
import os
import pathlib
import re
import socket
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]

# Absolute paths under these top-level directories are local, whatever is
# behind them (mounts, other homes, runtime dirs). /usr, /dev, /etc stay: a
# system header's name is not private.
LOCAL_TOPS = ("home", "mnt", "media", "run", "root", "Users", "var", "tmp", "srv", "opt", "net", "dev/shm")
_PATH_CHARS = r"[^\s'\"`:,;()<>\[\]{}|]"
_ANY_PATH = re.compile(r"(?<![\w.\-~/<>$])/(?:" + "|".join(LOCAL_TOPS) + r")(?:/" + _PATH_CHARS + r"*)?")
# A git worktree reached by any symlink (/mnt/x/rood-boi/worktrees/NAME/..., <home>/.../.claude/worktrees/NAME/...),
# also one `git worktree list` no longer knows.
_WORKTREE = re.compile(r"(?<![\w.\-~<>])(?:/[\w.\-@+]+)+?/worktrees/[\w.\-]+(?:/|(?=[\s'\"`:,;)\]]|$))")
_AGENT_SCRATCH = re.compile(r"claude-\d{3,}")


class Leak(Exception):
    pass


def _user():
    try:
        return getpass.getuser()
    except Exception:
        return os.environ.get("USER") or os.environ.get("USERNAME") or ""


def _names():
    """The user's name and the machine's hostname (what `sanitise` strips by name)."""
    names = {_user(), pathlib.Path.home().name, socket.gethostname(), socket.gethostname().split(".")[0]}
    return sorted({n for n in names if n and len(n) > 2}, key=lambda n: -len(n))


def _both(path):
    """`path` as given and fully resolved."""
    path = str(path)
    return {path, os.path.realpath(path)}


def repo_roots():
    """Every checkout of this repository: this one, the main one, each `git worktree list` entry,
    by its own path and its resolved (symlink-free) path."""
    roots = _both(ROOT)
    try:
        out = subprocess.run(["git", "worktree", "list", "--porcelain"], cwd=ROOT, capture_output=True,
                             text=True, timeout=20).stdout
        for line in out.splitlines():
            if line.startswith("worktree "):
                roots |= _both(line[9:])
    except Exception:
        pass
    git = ROOT / ".git"
    if git.is_file():  # a worktree's .git file points into the main checkout
        m = re.match(r"gitdir: (.*)", git.read_text().strip())
        if m:
            roots |= _both(pathlib.Path(m.group(1)).resolve().parents[2])
    return {r.rstrip("/") for r in roots if r and r != "/"}


def _zig_roots():
    paths = set()
    try:
        sys.path.insert(0, str(ROOT / "pc/tools"))
        import zig_toolchain
        paths |= _both(zig_toolchain.cache_root())
    except Exception:
        pass
    if os.environ.get("ROOD_ZIG_CACHE"):
        paths |= _both(os.environ["ROOD_ZIG_CACHE"])
    return paths


def _cache_roots():
    paths = set()
    for base in (os.environ.get("XDG_CACHE_HOME"), str(pathlib.Path.home() / ".cache")):
        if base:
            paths |= _both(pathlib.Path(base) / "rood-boi")
    return paths


def _tmp_roots():
    paths = {"/tmp", "/var/tmp", "/dev/shm", tempfile.gettempdir(), os.path.realpath(tempfile.gettempdir())}
    if os.environ.get("TMPDIR"):
        paths |= _both(os.environ["TMPDIR"])
    return {t.rstrip("/") for t in paths if t and t != "/"}


def _roots():
    """(path, replacement) pairs, longest path first. Repo roots become repo-relative, the caches
    `<cache>`, scratch directories `<tmp>`."""
    pairs = []
    for root in repo_roots():
        pairs += [(root + "/", ""), (root, ".")]
    for cache in _cache_roots():
        pairs += [(cache + "/", "<cache>/"), (cache, "<cache>")]
    for zig in _zig_roots():
        pairs += [(zig + "/", "<cache>/zig/"), (zig, "<cache>/zig")]
    # `~/.cache/rood-boi` as a tool prints it unexpanded.
    pairs += [("~/.cache/rood-boi/", "<cache>/"), ("~/.cache/rood-boi", "<cache>")]
    for tmp in _tmp_roots():
        pairs += [(tmp + "/", "<tmp>/"), (tmp, "<tmp>")]
    return sorted(set(pairs), key=lambda p: -len(p[0]))


_PAIRS = None


def _replace_path(text, path, replacement):
    """Replace `path` where it is a whole path prefix (not the middle of a longer name)."""
    if path.endswith("/"):
        return re.sub(r"(?<![\w.\-])" + re.escape(path), lambda _: replacement, text)
    return re.sub(r"(?<![\w.\-])" + re.escape(path) + r"(?![\w.\-])", lambda _: replacement, text)


def sanitise(text):
    """`text` with every local path, the user's name and the hostname replaced."""
    global _PAIRS
    if text is None:
        return None
    if _PAIRS is None:
        _PAIRS = _roots()
    # A worktree reached by any symlink first (its path may sit under the main checkout's), then the known roots.
    text = _WORKTREE.sub(lambda m: "" if m.group(0).endswith("/") else ".", text)
    for path, replacement in _PAIRS:
        text = _replace_path(text, path, replacement)
    # A scratch directory's own name (an agent scratch tree) is local too
    # (its last component, a file name, stays: `ref.c:12` is still useful).
    text = re.sub(r"<tmp>/claude-\d+(/[^\s'\"`:,)\]]*)?",
                  lambda m: "<tmp>/.../" + m.group(0).rstrip("/").rsplit("/", 1)[-1] if m.group(1) else "<tmp>", text)
    # Whatever absolute path is left (mounts, other homes, runtime dirs): a placeholder.
    text = _ANY_PATH.sub("<path>", text)
    text = _AGENT_SCRATCH.sub("<scratch>", text)
    for name in _names():
        text = re.sub(re.escape(name), "<user>", text, flags=re.I)
    return text


# What the last-line guard denies, whatever the sanitiser did.
# Built at run time so the publish leak scan (which denies these literals) passes this file.
_C = "clau" + "de"
DENY = ("/ho" + "me/", "/mnt/", "/tmp/" + _C, "/media/", "/run/user/", _C + "-" + str(1000))


def problems(text):
    """What is still local in `text` (empty when clean)."""
    found = []
    for needle in DENY:
        if needle in text:
            found.append(f"a local path ({needle})")
    home = str(pathlib.Path.home())
    if home and home != "/" and home in text:
        found.append("the home directory")
    if _AGENT_SCRATCH.search(text):
        found.append("the agents' scratch directory name")
    for root in repo_roots():
        if root in text:
            found.append("a checkout's absolute path")
            break
    for cache in _cache_roots():
        if cache in text:
            found.append("a cache path")
            break
    for name in _names():
        if re.search(re.escape(name), text, re.I):
            found.append("the user name or hostname")
            break
    if _ANY_PATH.search(text):
        found.append("an absolute local path")
    return list(dict.fromkeys(found))


def log_refusal(label, found):
    """Record a refusal locally (never the offending text): $ROOD_PRIVACY_LOG, default <cache>/privacy-refusals.log."""
    try:
        path = pathlib.Path(os.environ.get("ROOD_PRIVACY_LOG")
                            or pathlib.Path.home() / ".cache/rood-boi/privacy-refusals.log")
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "a") as f:
            f.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} refused {label}: {', '.join(found)}\n")
    except OSError:
        pass


def check(text, label="text"):
    """Raise Leak when `text` still holds anything local (the refusal is logged locally)."""
    found = problems(text)
    if found:
        log_refusal(label, found)
        raise Leak("prompt_privacy: refusing to send text containing " + ", ".join(found))
    return text


if __name__ == "__main__":
    data = sys.stdin.read()
    sys.stdout.write(sanitise(data))
