import json
import re
import ssl
import urllib.request
from pathlib import Path

links = []
pat = re.compile(r"\[[^\]]+\]\((https?://[^)\s]+)\)")
for path in Path(".").rglob("*.md"):
    if ".git" in path.parts or ".obsidian" in path.parts:
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    for line_no, line in enumerate(text.splitlines(), 1):
        for match in pat.finditer(line):
            links.append((str(path), line_no, match.group(1)))

urls = sorted({url for _, _, url in links})
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

results = []
for url in urls:
    status = None
    final = url
    error = ""

    head_req = urllib.request.Request(
        url, method="HEAD", headers={"User-Agent": "Mozilla/5.0"}
    )
    try:
        with urllib.request.urlopen(head_req, timeout=12, context=ctx) as response:
            status = response.getcode()
            final = response.geturl()
    except Exception:
        get_req = urllib.request.Request(
            url, method="GET", headers={"User-Agent": "Mozilla/5.0"}
        )
        try:
            with urllib.request.urlopen(get_req, timeout=15, context=ctx) as response:
                status = response.getcode()
                final = response.geturl()
        except Exception as exc:
            error = str(exc)

    results.append({"url": url, "status": status, "final": final, "error": error})

Path("link_check.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

bad = [r for r in results if (r["status"] is None) or (r["status"] >= 400)]
redirected = [r for r in results if r["status"] and r["final"] != r["url"]]

print(f"checked {len(results)}")
print(f"bad {len(bad)} redirected {len(redirected)}")
print("--- BAD ---")
for result in bad:
    print(f"{result['status']} | {result['url']} | {result['error']}")

print("--- REDIRECTS ---")
for result in redirected:
    print(f"{result['url']} -> {result['final']}")
