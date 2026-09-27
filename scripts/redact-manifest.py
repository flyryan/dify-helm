#!/usr/bin/env python3
"""Redact secret values in a rendered Helm manifest so it can be diffed on screen.

  scripts/redact-manifest.py [--secrets dify-prod-secrets.yaml] manifest.yaml > redacted.yaml

The chart copies credentials into several places (Secret data, plain ConfigMaps such
as dify-api/dify-worker and weaviate-config, inline env, and inside URLs such as
CELERY_BROKER_URL), so redaction is two-pass:

1. Collect secret values: every value under `data:`/`stringData:` of a Secret
   (base64-decoded too), every value whose key or env name looks sensitive (KEY,
   SECRET, PASS, TOKEN, USERS), and every scalar in the --secrets values file.
2. Mask those values wherever they occur, then mask the sensitive-keyed lines
   themselves.

Each value becomes `<redacted:sha256-prefix>`, so a diff of two redacted manifests
still shows that a credential changed without showing it. Values shorter than 8
characters or made only of lowercase letters (e.g. `postgres`) are masked only on
their own lines, not everywhere, so ordinary words in the manifest stay readable.
Standard library only; the output never contains a collected value.
"""

import base64
import hashlib
import re
import sys

SENSITIVE = re.compile(r"KEY|SECRET|PASS|TOKEN|USERS", re.I)


def mask(value: str) -> str:
    return "<redacted:" + hashlib.sha256(value.encode()).hexdigest()[:10] + ">"


def clean(value: str) -> str:
    return value.strip().strip("'\"")


def collect(text: str, secrets_file: str | None) -> set[str]:
    vals: set[str] = set()
    for doc in re.split(r"\n---\n", text):
        is_secret = re.search(r"^kind:\s*Secret\s*$", doc, re.M)
        in_data = False
        for line in doc.split("\n"):
            if re.match(r"^(data|stringData):\s*$", line):
                in_data = True
                continue
            if in_data and line and not line.startswith(" "):
                in_data = False
            kv = re.match(r"^\s+([^\s:#][^:]*):\s*(\S.*)$", line)
            if kv and ((is_secret and in_data) or SENSITIVE.search(kv.group(1))):
                v = clean(kv.group(2))
                vals.add(v)
                if is_secret and in_data:
                    try:
                        vals.add(base64.b64decode(v, validate=True).decode())
                    except Exception:
                        pass
        for m in re.finditer(r"- name:\s*(\S+)\s*\n\s+value:\s*(\S.*)", doc):
            if SENSITIVE.search(m.group(1)):
                vals.add(clean(m.group(2)))
    if secrets_file:
        for m in re.finditer(r"^\s*(?:-\s+)?(?:[\w.-]+:\s*)?(\S.*?)\s*$", open(secrets_file).read(), re.M):
            v = clean(m.group(1))
            if v and not v.endswith(":") and not v.startswith("#"):
                vals.add(v)
    return {v for v in vals if v and v.lower() not in ("true", "false", "null", "")}


def global_candidates(vals: set[str]) -> list[str]:
    return sorted((v for v in vals if len(v) >= 8 and not re.fullmatch(r"[a-z]+", v)), key=len, reverse=True)


def redact(text: str, vals: set[str]) -> str:
    for v in global_candidates(vals):
        text = text.replace(v, mask(v))
    out = []
    for doc in re.split(r"(\n---\n)", text):
        is_secret = re.search(r"^kind:\s*Secret\s*$", doc, re.M)
        lines, in_data = doc.split("\n"), False
        for i, line in enumerate(lines):
            if re.match(r"^(data|stringData):\s*$", line):
                in_data = True
                continue
            if in_data and line and not line.startswith(" "):
                in_data = False
            kv = re.match(r"^(\s+[^\s:#][^:]*):\s*(\S.*)$", line)
            if kv and "<redacted:" not in kv.group(2) and ((is_secret and in_data) or SENSITIVE.search(kv.group(1))):
                lines[i] = f"{kv.group(1)}: {mask(clean(kv.group(2)))}"
            name = re.match(r"^\s*- name:\s*(\S+)\s*$", line)
            if name and SENSITIVE.search(name.group(1)) and i + 1 < len(lines):
                val = re.match(r"^(\s+value:)\s*(\S.*)$", lines[i + 1])
                if val and "<redacted:" not in val.group(2):
                    lines[i + 1] = f"{val.group(1)} {mask(clean(val.group(2)))}"
        out.append("\n".join(lines))
    return "".join(out)


def main() -> None:
    args, secrets_file = sys.argv[1:], None
    if args[:1] == ["--secrets"]:
        secrets_file, args = args[1], args[2:]
    text = open(args[0]).read() if args else sys.stdin.read()
    sys.stdout.write(redact(text, collect(text, secrets_file)))


if __name__ == "__main__":
    main()
