"""Compose the M3-5A review and approval sheets from the rendered panels.

Usage: python3 compose_sheets.py <cotton_panels> <monitor_panels> <cadet_renders> <impact_frames_dir> <young_preview_34.png> <bridge_panels>
Writes
  production/concept/ch05_assets/M3-5A_cotton_stages_v1.png
  production/concept/ch05_assets/M3-5A_impact_monitor_v1.png
  production/concept/ch05_assets/M3-5A_cadet_duty_coverage_v1.png
  production/concept/ch05_assets/M3-5A_ferreira_duty_v1.png
  production/concept/ch05_assets/M3-5A_bridge_props_v1.png
  production/review/M3-5A_ch05_assets_contact.png   (all five stacked)
  production/qa/evidence/M3-5A_contact.png           (the same, for the task evidence)
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
BG, INK, MUTED, FLAG = (236, 236, 236), (31, 42, 68), (90, 96, 108), (176, 70, 20)


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)


def wrap(text, fnt, width):
    """Splits `text` into lines no wider than `width` pixels in `fnt`."""
    lines, line = [], ""
    for word in text.split():
        trial = (line + " " + word).strip()
        if fnt.getlength(trial) <= width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + ([line] if line else [])


def tile(path, title, when, note, w=600, h=720, fit=None):
    img = Image.open(path).convert("RGB")
    cap = 150
    if fit:
        img = img.crop(fit)
    img = ImageOps.contain(img, (w - 8, h - cap - 8), Image.LANCZOS)   # fit the box, upscaling small images too
    t = Image.new("RGB", (w, h), BG)
    t.paste(img, ((w - img.width) // 2, 4))
    d = ImageDraw.Draw(t)
    y = h - cap + 8
    d.text((16, y), title, font=font(26 if w >= 500 else 20, True), fill=INK)
    d.text((16, y + 34), when, font=font(19 if w >= 500 else 15), fill=FLAG if "approval" in when.lower() else MUTED)
    for i, line in enumerate(wrap(note, font(17 if w >= 500 else 14), w - 32)[:3]):
        d.text((16, y + 62 + i * 22), line, font=font(17 if w >= 500 else 14), fill=MUTED)
    return t


def header(w, title, sub):
    lines = wrap(sub, font(21), w - 56)
    hd = Image.new("RGB", (w, 92 + 28 * len(lines)), (31, 42, 68))
    d = ImageDraw.Draw(hd)
    d.text((28, 22), title, font=font(40 if font(40, True).getlength(title) < w - 56 else 30, True), fill=(242, 194, 48))
    for i, line in enumerate(lines):
        d.text((28, 78 + 28 * i), line, font=font(21), fill=(236, 238, 240))
    return hd


def sheet(cols, tiles, w, h, title, sub):
    rows = (len(tiles) + cols - 1) // cols
    hd = header(cols * w, title, sub)
    out = Image.new("RGB", (cols * w, hd.height + rows * h), BG)
    out.paste(hd, (0, 0))
    for i, t in enumerate(tiles):
        out.paste(t, ((i % cols) * w, hd.height + (i // cols) * h))
    return out


def frames_strip(frames_dir, w, h):
    """Candidate C01 (artifact) and C02 (genuine), cameras a and b, frames 0-2: an 80 x 50 px window round each
    candidate's detector position, enlarged 4x with nearest sampling so single pixels stay visible."""
    data = json.load(open(os.path.join(frames_dir, "impact_frames.json")))
    by = {c["id"]: c for c in data["candidates"]}
    off = data.get("camera_b_offset_px", [0, 0])
    cw, ch, z = 80, 50, 4
    tw, th = cw * z, ch * z
    grid = Image.new("RGB", (3 * tw + 8, 4 * th + 12 + 70), (18, 22, 30))
    d = ImageDraw.Draw(grid)
    for r, (cid, cam) in enumerate((("C01", "a"), ("C01", "b"), ("C02", "a"), ("C02", "b"))):
        x, y = by[cid]["detector_xy"]
        if cam == "b":
            x, y = x + off[0], y + off[1]
        box = (x - cw // 2, y - ch // 2, x + cw // 2, y + ch // 2)
        for k in range(3):
            im = Image.open(os.path.join(frames_dir, by[cid]["frames"][cam][k])).convert("RGB").crop(box)
            grid.paste(im.resize((tw, th), Image.NEAREST), (k * (tw + 4), r * (th + 4)))
        d.text((6, r * (th + 4) + 4), f"{cid} {by[cid]['kind']}, camera {cam}", font=font(15, True), fill=(220, 225, 235))
    legend = ("Columns: frame before, event, after; each window is centred on the candidate's detector position (4x). "
              "C01: a fixed hot pixel in camera a only, in all three frames. C02: one flash in frame 1, seen by both cameras.")
    for i, line in enumerate(wrap(legend, font(17), grid.width - 12)):
        d.text((6, 4 * th + 18 + i * 22), line, font=font(17), fill=(200, 205, 215))
    grid = ImageOps.contain(grid, (w - 8, h - 150 - 8), Image.LANCZOS)
    t = Image.new("RGB", (w, h), BG)
    t.paste(grid, ((w - grid.width) // 2, 4))
    dd = ImageDraw.Draw(t)
    y = h - 150 + 8
    dd.text((16, y), "Authored frame set (60 PNG, 320 x 200)", font=font(26, True), fill=INK)
    dd.text((16, y + 34), "8 genuine transients + 2 fixed artifacts; 6 verified = mission, 8 = Golden", font=font(19), fill=MUTED)
    dd.text((16, y + 62), "Teaching set, never an imported observation; timestamps and reason chips are live UI.", font=font(17), fill=MUTED)
    return t


def main(cotton, monitor, cadets, frames_dir, young, bridge):
    W, H = 600, 720
    cotton_tiles = [
        tile(os.path.join(cotton, "PL_Cotton_Seed_top34.png"), "PL_Cotton_Seed", "15 Dec 2046, EX-CH05-S12 planting", "Acid-delinted 9.5 mm seed half-covered in its sowing dimple; the PL_Cotton_Young pot. 2.8k tris."),
        tile(os.path.join(cotton, "PL_Cotton_Sprout_34.png"), "PL_Cotton_Sprout", "about 22-25 Dec (5-10 days after sowing)", "Hypocotyl 3.8 cm, two kidney-shaped cotyledons unfolded. 5.5k tris, 13.4 cm."),
        tile(os.path.join(cotton, "PL_Cotton_Seedling_34.png"), "PL_Cotton_Seedling", "early Jan 2047, dated care", "First heart-shaped true leaf, second leaf folded at the tip. 9.1k tris, 18.0 cm."),
        tile(young, "PL_Cotton_Young (installed)", "first light, Jan-Feb 2047, to CH08-S12", "Existing Tripo model, 32 cm, lobed leaves, no boll. Shown for the stage order only."),
        tile(os.path.join(cotton, "PL_Cotton_Seedling_front.png"), "Seedling, front", "orthographic", "Healthy rest pose: all blend-shape weights 0 in the GLB."),
        tile(os.path.join(cotton, "PL_Cotton_Seedling_shape_Thirst.png"), "Seedling, blend shape Thirst", "biology service sets the weight", "Cotyledons and leaf droop, hypocotyl leans: silhouette changes, not only colour."),
        tile(os.path.join(cotton, "PL_Cotton_Seedling_shape_Cold.png"), "Seedling, blend shape Cold", "biology service sets the weight", "Blades cup downward and tuck in."),
        tile(os.path.join(cotton, "PL_Cotton_Sprout_shape_Thirst.png"), "Sprout, blend shape Thirst", "biology service sets the weight", "The same two states exist on the sprout."),
    ]
    cotton_sheet = sheet(4, cotton_tiles, W, H, "M3-5A for review: cotton seed, sprout and seedling (installed, gate-verified)",
                         "Gossypium hirsutum stages for Tara's bay from 15 Dec. Blender procedural geometry on the reused PL_Cotton_Young pot; no AI image, no credits. No eyes, face or mouth.")
    cotton_sheet.save(os.path.join(HERE, "M3-5A_cotton_stages_v1.png"), optimize=True)

    monitor_tiles = [
        tile(os.path.join(monitor, "PR_ImpactMonitor_34.png"), "PR_ImpactMonitor, three-quarter", "EX-CH05-S07, Aurora impact-camera monitor", "Navy plinth, deck tilted 18 deg on a wedge riser, white head, orange grab handles. 7.2k tris, 56 cm."),
        tile(os.path.join(monitor, "PR_ImpactMonitor_front.png"), "Front", "Screen = live-UI surface (kit convention)", "Six blank keys (orange reject, gold verify), compare bar, jog wheel, cyan status strip. No baked text."),
        tile(os.path.join(monitor, "PR_ImpactMonitor_side.png"), "Side", "head tilted back 12 deg, deck 18 deg", "Sockets: Socket_Focus in front of the screen, Socket_Hand on the jog wheel."),
        tile(os.path.join(monitor, "PR_ImpactMonitor_back.png"), "Back", "vents and cable gland", "Moving children: JogWheel (axle), Key_01-06 (press), for the P-10 panel (M3-5P)."),
        frames_strip(frames_dir, W * 2, H),
    ]
    hd = header(4 * W, "M3-5A for review: impact-camera monitor and its frame set (installed, gate-verified)",
                "Flashes are small points on a dark plain: no streaks, no trails (ART_BIBLE 2). Blender procedural + Python-authored frames; no AI image, no credits.")
    monitor_sheet = Image.new("RGB", (4 * W, hd.height + 2 * H), BG)
    monitor_sheet.paste(hd, (0, 0))
    for i, t in enumerate(monitor_tiles[:4]):
        monitor_sheet.paste(t, (i * W, hd.height))
    monitor_sheet.paste(monitor_tiles[4], (W, hd.height + H))
    states = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(states)
    d.text((16, 14), "Monitor states", font=font(26, True), fill=INK)
    lines = ["Candidate: one enlarged frame, camera a", "Paired reference: camera a beside camera b,", "   same frame (a real flash is in both;", "   a hot pixel in a only)",
             "Artifact rejection: frames before, event,", "   after (a real flash has an onset;", "   a hot pixel is in all three)", "Six verified: mission exit gate", "Eight mastery: Golden, no false report",
             "", "Data: game/assets/ui/impact_monitor/", "impact_frames.json (M3-5P reads it)"]
    for i, l in enumerate(lines):
        d.text((16, 60 + i * 30), l, font=font(19), fill=MUTED)
    monitor_sheet.paste(states, (0, hd.height + H))
    monitor_sheet.save(os.path.join(HERE, "M3-5A_impact_monitor_v1.png"), optimize=True)

    cadet_tiles = []
    for name, note in (("Kai", "orange tabs, tool belt, cable"), ("Amara", "cyan tabs, tablet on the thigh"), ("Mei", "green tabs, apron bow"), ("Rafi", "purple tabs, safety vest")):
        for view in ("front", "side", "back"):
            cadet_tiles.append(tile(os.path.join(cadets, f"CH_{name}_{view}.png"), f"CH_{name}, {view}", "installed v7/v8 build, navy duty coverall", note + "; one arm per side (check PASS)", W // 2, H - 200, fit=(120, 60, 780, 840)))
    cadet_sheet = sheet(6, cadet_tiles, W // 2, H - 200, "M3-5A coverage check: CH_Cadet_DutyLayer = the installed cadets' indoor navy coverall",
                        "Registry row resolved by reuse: the four installed GLBs are the duty layer (ART_BIBLE 5). Rest pose (first clip cleared). Side-view slice check: 1 depth cluster at forearm height for all four (no mirrored arm); bone probe: one forearm and hand per side; the v7 rest pose holds the left hand 0.15-0.25 m forward on every cadet and Kai's and Mei's right hand about 0.2 m back, which is why Mei's side view shows both arms. Flag on the left sleeve, Aurora patch on the right. No credits.")
    cadet_sheet.save(os.path.join(HERE, "M3-5A_cadet_duty_coverage_v1.png"), optimize=True)

    fd = os.path.join(HERE, "ferreira_duty")
    fer_tiles = [
        tile(os.path.join(ROOT, "game/assets/ui/portraits/CH_Ferreira_screen.png"), "Now installed: CH_Ferreira_screen.png", "Godot render of the Aurora coverall (M1-17)", "Shown on the Earth screen before 12 Dec, where canon has her in a civilian duty layer.", W, 520),
        tile(os.path.join(fd, "take1_a.png"), "Take A (new)", "NEEDS APPROVAL: pick A, B, or ask for changes", "Charcoal fleece over a grey T-shirt, gear-wheel patch, field watch; mission control at night; hands folded.", W, 520),
        tile(os.path.join(fd, "take1_b.png"), "Take B (new)", "NEEDS APPROVAL: pick A, B, or ask for changes", "Same brief, slight smile, Moon disc and plain graphs behind; screens carry lines, no words.", W, 520),
        tile(os.path.join(ROOT, "game/assets/ui/portraits/CH_Rao_screen.png"), "Style reference: CH_Rao_screen.png", "the Earth-desk portrait already in the game", "The duty portrait matches Rao's illustrated screen style and his control room.", W, 520),
    ]
    fer_sheet = sheet(4, fer_tiles, W, 520, "M3-5A for approval: CH_Ferreira_Duty, the Earth duty-layer screen portrait (before 12 Dec 2046)",
                      "Tripo image, gemini_3_pro_image_preview, image-to-image from the approved v8 front view; 2 takes, balance 1325 before and after. Portrait only: she is never physical before 12 Dec, so no 3D body is needed.")
    fer_sheet.save(os.path.join(HERE, "M3-5A_ferreira_duty_v1.png"), optimize=True)

    bridge_tiles = [
        tile(os.path.join(bridge, "PR_DocumentSleeve_34.png"), "PR_DocumentSleeve", "CH05 S02 to S03: relief cargo, shelf, then the table", "Rigid A4 case, hinged Lid, orange tamper Seal (hidden once opened), blank Label window. 33.5 cm."),
        tile(os.path.join(bridge, "PR_Records2034_top34.png"), "PR_Records2034", "CH05-S03 clue 17: four records under clear weights", "Relay fault report, greenhouse service note, evacuation order, ascent manifest; set down unarranged."),
        tile(os.path.join(bridge, "PR_Records2034_34.png"), "Records, low view", "D9: one record stays at Ferreira's place", "Each sheet pivots at its own centre, so the manifest or the service note can move alone to CH06-CH08."),
        tile(os.path.join(bridge, "PR_MarkerTape_34.png"), "PR_MarkerTape", "CH05 to CH06-S01: Kai marks the guide-light branch", "19 mm vinyl in Kai's orange: Roll, and one Strip wrapped on a 12 mm cable with Socket_Cable on its axis."),
    ]
    bridge_sheet = sheet(4, bridge_tiles, W, H, "M3-5A for review: the objects Chapter 5's scene joins carry (installed, gate-verified)",
                         "Doc 24 2.9 and clues 17-18. Blank printed forms: every word, signature and Ferreira's margin note (back of the order) is live document text, never baked. No credits.")
    bridge_sheet.save(os.path.join(HERE, "M3-5A_bridge_props_v1.png"), optimize=True)

    cw = 2400
    parts = [cotton_sheet, monitor_sheet, bridge_sheet, cadet_sheet, fer_sheet]
    scaled = [p.resize((cw, int(p.height * cw / p.width)), Image.LANCZOS) for p in parts]
    total = sum(p.height for p in scaled) + 20 * (len(scaled) - 1)
    contact = Image.new("RGB", (cw, total), (20, 24, 32))
    y = 0
    for p in scaled:
        contact.paste(p, (0, y))
        y += p.height + 20
    os.makedirs(os.path.join(ROOT, "production", "review"), exist_ok=True)
    contact.save(os.path.join(ROOT, "production", "review", "M3-5A_ch05_assets_contact.png"), optimize=True)
    contact.save(os.path.join(ROOT, "production", "qa", "evidence", "M3-5A_contact.png"), optimize=True)
    print("sheets written")


if __name__ == "__main__":
    main(*sys.argv[1:7])
