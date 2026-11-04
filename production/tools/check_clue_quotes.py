"""Check every canon line quoted in 22_PUZZLE_CLUE_DESIGN.md against story-data.json, and 08 hint quotes against 08."""
import json, re, sys
root = sys.argv[1]
doc = open(f"{root}/game-design/22_PUZZLE_CLUE_DESIGN.md", encoding="utf-8").read()
lines = {}
for c in json.load(open(f"{root}/full-game-story/story-data.json", encoding="utf-8"))["chapters"]:
    for s in c["scenes"]:
        for l in s["dialogue"]:
            lines[l["id"]] = l["line"]
# an ID (full or `Lxx` shorthand), then up to 80 chars without another backtick-ID, then "quote"
pat = re.compile(r'`(EX-CH\d\d-S\d\d-L\d\d|L\d\d)`(:?(?: [A-Z][\w .()\'’-]{0,45}:)? ?\(?)"([^"]+)"')
bad, n, last_scene = [], 0, None
for m in pat.finditer(doc):
    ref, quote = m.group(1), m.group(3)
    if ref.startswith("EX-"):
        last_scene = ref[:-4]
        lid = ref
    else:
        if not last_scene:
            continue
        lid = f"{last_scene}-{ref}"
    canon = lines.get(lid)
    n += 1
    if canon is None:
        bad.append(f"unknown id {lid}")
    elif quote != canon:
        bad.append(f"{lid}: doc={quote!r} canon={canon!r}")
# every ID mentioned must exist
for lid in set(re.findall(r"EX-CH\d\d-S\d\d-L\d\d", doc)):
    if lid not in lines:
        bad.append(f"unknown id {lid}")
# 08 hint quotes: H1/H2/H3/G1/G2 text after '08 P-xx' markers must appear verbatim in 08
p08 = open(f"{root}/game-design/08_PUZZLE_DESIGNS.md", encoding="utf-8").read()
for m in re.finditer(r"08 P-\d\d([^:]*):(.*?)(?=\(`NEW`\)|\*\*Modes|\n|$)", doc):
    if "NEW" in m.group(1):
        continue
    for q in re.findall(r'(?:H\d|G\d) "([^"]+)"', m.group(2)):
        if q not in p08:
            bad.append(f"08 hint not verbatim: {q!r}")
print(f"checked {n} quoted lines")
print("\n".join(bad) if bad else "all quotes match canon")
sys.exit(1 if bad else 0)
