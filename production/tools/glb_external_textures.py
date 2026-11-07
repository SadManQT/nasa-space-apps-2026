"""Move the textures a GLB embeds out to shared PNG files next to it, so a kit stores each texture once.

    python3 production/tools/glb_external_textures.py <piece.glb> [<piece.glb> ...] [--dir textures]

Blender's glTF exporter embeds every image in every GLB it writes. For a modular kit that tiles the same
four PBR sets over 24 files, that stores each texture 24 times on disk and once per piece in VRAM, which
the handbook forbids ("textures are never stored twice"). This tool rewrites a GLB so that each image is a
`uri` to `<dir>/<image name>.png` beside the GLB (written only when missing or different), and drops the
image bytes from the binary chunk. Godot 4 loads such a uri through ResourceLoader, so every piece shares
the one imported CompressedTexture2D, and the project's own `.png.import` settings (VRAM compression,
mipmaps, normal maps) apply.

Pure Python (no Blender), so build scripts can call `externalise(path, dir)` after export and the same
function can be run on already-published files. Prints one line per GLB: images moved and the size change.
"""
import json
import struct
import sys
from pathlib import Path

MAGIC = 0x46546C67  # "glTF"
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942
EXTENSIONS = {"image/png": ".png", "image/jpeg": ".jpg"}


def _read_glb(path):
    data = Path(path).read_bytes()
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != MAGIC or version != 2:
        raise ValueError(f"{path}: not a glTF 2 binary")
    offset, doc, binary = 12, None, b""
    while offset < length:
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8: offset + 8 + chunk_length]
        if chunk_type == CHUNK_JSON:
            doc = json.loads(chunk)
        elif chunk_type == CHUNK_BIN:
            binary = chunk
        offset += 8 + chunk_length
    if doc is None:
        raise ValueError(f"{path}: no JSON chunk")
    return doc, binary


def _write_glb(path, doc, binary):
    body = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    body += b" " * (-len(body) % 4)
    binary = bytes(binary) + b"\0" * (-len(binary) % 4)
    chunks = struct.pack("<II", len(body), CHUNK_JSON) + body
    if binary:
        chunks += struct.pack("<II", len(binary), CHUNK_BIN) + binary
    Path(path).write_bytes(struct.pack("<III", MAGIC, 2, 12 + len(chunks)) + chunks)


def _remap_buffer_views(doc, keep):
    """Renumbers bufferView references after the views in `keep` (old indices, in order) survive."""
    index = {old: new for new, old in enumerate(keep)}

    def fix(obj):
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key == "bufferView" and isinstance(value, int):
                    obj[key] = index[value]
                else:
                    fix(value)
        elif isinstance(obj, list):
            for value in obj:
                fix(value)

    fix({k: v for k, v in doc.items() if k != "bufferViews"})


def externalise(glb_path, texture_dir="textures", write_files=True):
    """Rewrites one GLB in place; returns (images moved, bytes before, bytes after). A GLB with no embedded
    images is left untouched. Image files land in <glb folder>/<texture_dir>/<image name><ext>.
    With write_files False nothing is written to the texture folder: the GLB only *references* the files that
    are already there (a kit extension in another folder pointing at "../kit/textures", board M3-2A), so the
    shared set is never rewritten by a second build. texture_dir may also be a callable image name -> folder, for a
    GLB that references more than one shared set (M3-4A: the kit's sets beside the garage's own)."""
    glb_path = Path(glb_path)
    before = glb_path.stat().st_size
    doc, binary = _read_glb(glb_path)
    images = doc.get("images", [])
    embedded = [i for i, image in enumerate(images) if "bufferView" in image]
    if not embedded:
        return 0, before, before
    removed = set()
    for i in embedded:
        image = images[i]
        view = doc["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        payload = binary[start: start + view["byteLength"]]
        mime = image.get("mimeType", "image/png")
        name = image.get("name") or f"{glb_path.stem}_image{i}"
        folder = texture_dir(name) if callable(texture_dir) else texture_dir
        out_dir = glb_path.parent / folder
        if write_files:
            out_dir.mkdir(parents=True, exist_ok=True)
        target = out_dir / (name + EXTENSIONS.get(mime, ".png"))
        if write_files and (not target.exists() or target.read_bytes() != payload):
            target.write_bytes(payload)
        elif not write_files and not target.exists():
            raise FileNotFoundError(f"{glb_path.name} references {target}, which does not exist")
        removed.add(image["bufferView"])
        images[i] = {"name": name, "mimeType": mime, "uri": f"{folder}/{target.name}"}
    keep = [i for i in range(len(doc["bufferViews"])) if i not in removed]
    new_binary = bytearray()
    new_views = []
    for i in keep:
        view = dict(doc["bufferViews"][i])
        start = view.pop("byteOffset", 0)
        new_binary += b"\0" * (-len(new_binary) % 4)
        view["byteOffset"] = len(new_binary)
        new_binary += binary[start: start + view["byteLength"]]
        new_views.append(view)
    _remap_buffer_views(doc, keep)
    doc["bufferViews"] = new_views
    if doc.get("buffers"):
        doc["buffers"][0]["byteLength"] = len(new_binary)
    _write_glb(glb_path, doc, new_binary)
    return len(embedded), before, glb_path.stat().st_size


def main(argv):
    texture_dir = "textures"
    paths = []
    args = iter(argv)
    for arg in args:
        if arg == "--dir":
            texture_dir = next(args)
        else:
            paths.append(arg)
    if not paths:
        sys.exit(__doc__)
    for path in paths:
        moved, before, after = externalise(path, texture_dir)
        print(f"{Path(path).name}: {moved} images -> {texture_dir}/, {before // 1024} KB -> {after // 1024} KB")


if __name__ == "__main__":
    main(sys.argv[1:])
