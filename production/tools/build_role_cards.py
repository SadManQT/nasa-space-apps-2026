#!/usr/bin/env python3
"""Printable crew notes (role cards) for Class mode, built from the same data the game reads.

    python3 production/tools/build_role_cards.py                      # writes docs/classroom/role_cards/
    python3 production/tools/build_role_cards.py --out some/dir --dpi 150

Sources: game/resources/campaign/content/p02_mission_table.json (role facts, quotes, arrival shifts)
and game/resources/campaign/content/crew_modes.json (seat plans and every printed word). Output is
one A5 landscape PNG per role, a cover sheet with the how-to and seat plans, and one PDF with all
five pages. Pure Pillow drawing: no image generation service, no credits. Fonts come from the
system (Arial on macOS) with Pillow's bundled fallback, so the text, not the font, is the deliverable.
"""
import argparse
import json
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
TABLE = ROOT / "game/resources/campaign/content/p02_mission_table.json"
CREW = ROOT / "game/resources/campaign/content/crew_modes.json"
A5_MM = (210, 148)  # landscape
INK = (5, 6, 10)
IVORY = (236, 238, 240)
NAVY = (31, 42, 68)
MUTED = (96, 108, 128)
FONT_CANDIDATES = {
    "bold": ["/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial Bold.ttf",
             "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"],
    "regular": ["/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "C:/Windows/Fonts/arial.ttf"],
}


def font(kind: str, size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES[kind]:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def hex_color(value: str) -> tuple:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, width: int) -> list:
    """Word-wrap `text` so each line fits `width` pixels in `fnt`."""
    lines, line = [], ""
    for word in text.split():
        candidate = (line + " " + word).strip()
        if draw.textlength(candidate, font=fnt) <= width or not line:
            line = candidate
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def paragraph(draw, xy, text, fnt, width, fill, leading=1.25) -> int:
    """Draw wrapped text at xy; returns the y below it."""
    x, y = xy
    step = int(fnt.size * leading)
    for line in wrap(draw, text, fnt, width):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += step
    return y


def seat_line(crew: dict, players: int, role_id: str) -> str:
    for seat in crew["seat_plans"][str(players)]:
        if role_id in seat["role_ids"]:
            return crew["seat_label"].replace("{seat}", str(seat["seat"]))
    return "-"


def role_card(card: dict, crew: dict, size: tuple, dpi: int) -> Image.Image:
    role_id = card["role_id"]
    info = crew["roles"][role_id]
    accent = hex_color(info["color"])
    image = Image.new("RGB", size, IVORY)
    draw = ImageDraw.Draw(image)
    margin = int(size[0] * 0.05)
    bar = int(size[0] * 0.018)
    draw.rectangle([0, 0, bar, size[1]], fill=accent)
    width = size[0] - margin * 2 - bar
    x = margin + bar
    y = margin
    small = font("regular", int(dpi * 0.09))
    draw.text((x, y), crew["print"]["title"], font=small, fill=MUTED)
    stamp = crew["print"]["private_stamp"].replace("{holder}", "keep it face down until you share")
    stamp_w = draw.textlength(stamp, font=small)
    draw.text((size[0] - margin - stamp_w, y), stamp, font=small, fill=accent)
    y += int(small.size * 1.9)
    name = font("bold", int(dpi * 0.36))
    draw.text((x, y), card["name"].upper(), font=name, fill=INK)
    duty = font("regular", int(dpi * 0.17))
    duty_text = info["duty"]
    draw.text((x + draw.textlength(card["name"].upper(), font=name) + int(dpi * 0.15), y + int(name.size * 0.42)), duty_text, font=duty, fill=NAVY)
    y += int(name.size * 1.25)
    chip = font("bold", int(dpi * 0.11))
    arrives = crew["print"]["arrives"].replace("{shift}", str(card["arrives_shift"]))
    seats = "  ·  ".join(f"{players} players: {seat_line(crew, players, role_id)}" for players in (4, 3, 2))
    draw.text((x, y), f"{arrives}   ·   {seats}", font=chip, fill=MUTED)
    y += int(chip.size * 2.0)
    if card.get("quote"):
        quote = font("regular", int(dpi * 0.17))
        y = paragraph(draw, (x, y), f"\u201c{card['quote']}\u201d  — {card['name']}", quote, width, hex_color(info["color"]))
        y += int(quote.size * 0.6)
    body = font("regular", int(dpi * 0.165))
    bullet_indent = int(dpi * 0.24)
    for fact in card["facts"]:
        draw.text((x, y), "\u2022", font=body, fill=accent)
        y = paragraph(draw, (x + bullet_indent, y), fact, body, width - bullet_indent, INK)
        y += int(body.size * 0.45)
    footer = font("regular", int(dpi * 0.085))
    footer_lines = wrap(draw, crew["print"]["footer"], footer, width)
    fy = size[1] - margin - len(footer_lines) * int(footer.size * 1.3)
    for line in footer_lines:
        draw.text((x, fy), line, font=footer, fill=MUTED)
        fy += int(footer.size * 1.3)
    return image


def cover_sheet(crew: dict, cards: list, size: tuple, dpi: int) -> Image.Image:
    image = Image.new("RGB", size, IVORY)
    draw = ImageDraw.Draw(image)
    margin = int(size[0] * 0.05)
    width = size[0] - margin * 2
    y = margin
    title = font("bold", int(dpi * 0.26))
    draw.text((margin, y), crew["print"]["title"], font=title, fill=INK)
    y += int(title.size * 1.3)
    sub = font("regular", int(dpi * 0.13))
    y = paragraph(draw, (margin, y), crew["print"]["subtitle"], sub, width, NAVY)
    y += int(sub.size * 0.8)
    body = font("regular", int(dpi * 0.125))
    for index, step in enumerate(crew["print"]["how_to"], start=1):
        y = paragraph(draw, (margin, y), f"{index}.  {step}", body, width, INK)
        y += int(body.size * 0.35)
    y += int(body.size * 0.6)
    heading = font("bold", int(dpi * 0.13))
    draw.text((margin, y), "SEAT PLANS", font=heading, fill=INK)
    y += int(heading.size * 1.5)
    joiner = crew["menu"]["seat_plan_joiner"]
    for players in (2, 3, 4):
        parts = []
        for seat in crew["seat_plans"][str(players)]:
            names = joiner.join(crew["roles"][r]["name"] for r in seat["role_ids"])
            parts.append(f"{crew['seat_label'].replace('{seat}', str(seat['seat']))}: {names}")
        y = paragraph(draw, (margin, y), f"{players} players  ·  " + "   ·   ".join(parts), body, width, INK)
        y += int(body.size * 0.3)
    y += int(body.size * 0.4)
    y = paragraph(draw, (margin, y), crew["seat_plan_note"], font("regular", int(dpi * 0.105)), width, MUTED)
    y += int(body.size * 0.8)
    draw.text((margin, y), "ARRIVAL", font=heading, fill=INK)
    y += int(heading.size * 1.5)
    arrivals = "   ·   ".join(f"{c['name']}: shift {c['arrives_shift']}" for c in cards)
    y = paragraph(draw, (margin, y), arrivals, body, width, INK)
    footer = font("regular", int(dpi * 0.085))
    lines = wrap(draw, crew["print"]["footer"], footer, width)
    fy = size[1] - margin - len(lines) * int(footer.size * 1.3)
    for line in lines:
        draw.text((margin, fy), line, font=footer, fill=MUTED)
        fy += int(footer.size * 1.3)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=str(ROOT / "docs/classroom/role_cards"))
    parser.add_argument("--dpi", type=int, default=150)
    args = parser.parse_args()
    table = json.loads(TABLE.read_text())
    crew = json.loads(CREW.read_text())
    size = (round(A5_MM[0] / 25.4 * args.dpi), round(A5_MM[1] / 25.4 * args.dpi))
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    cards = sorted(table["role_cards"], key=lambda c: crew["role_order"].index(c["role_id"]))
    pages = [cover_sheet(crew, cards, size, args.dpi)]
    pages[0].save(out / "00_cover_sheet.png", dpi=(args.dpi, args.dpi))
    for index, card in enumerate(cards, start=1):
        image = role_card(card, crew, size, args.dpi)
        image.save(out / f"{index:02d}_{card['role_id']}_crew_note.png", dpi=(args.dpi, args.dpi))
        pages.append(image)
    pdf = out / "Last_Light_Academy_crew_notes.pdf"
    pages[0].save(pdf, save_all=True, append_images=pages[1:], resolution=args.dpi)
    print(f"wrote {len(pages)} pages at {size[0]}x{size[1]} px ({args.dpi} dpi) to {out}")


if __name__ == "__main__":
    main()
