import json, shlex


def owned(path, adir):
    try:
        with open(path) as f:
            hooks = (json.load(f) or {}).get("hooks") or {}
        cmds = sorted(h.get("command") for es in hooks.values() for e in es for h in e.get("hooks", []))
    except Exception:
        return False
    events = ("SessionEnd", "SessionStart")
    quoted = sorted(f"{shlex.quote(adir + '/hook.sh')} {ev}" for ev in events)
    return cmds in (quoted, sorted(f"{adir}/hook.sh {ev}" for ev in events))
