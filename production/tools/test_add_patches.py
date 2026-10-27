"""Array-only regression checks; no Blender scene, image export or generated assets are touched.

  python3 production/tools/test_add_patches.py
"""
import ast
from pathlib import Path
import numpy as np

# Load pure helpers without executing the Blender command's import/export entry point.
source = Path(__file__).with_name("add_patches.py")
names = {"raster", "dilate", "nb_sum", "pull_push", "blobs", "flag_green", "flag_mask", "fill", "linked_images"}
module = ast.parse(source.read_text())
scope = {"np": np}
exec(compile(ast.Module(body=[n for n in module.body if isinstance(n, ast.FunctionDef) and n.name in names], type_ignores=[]), str(source), "exec"), scope)
raster, dilate, nb_sum, pull_push, blobs, flag_green, flag_mask, fill = [scope[n] for n in ("raster", "dilate", "nb_sum", "pull_push", "blobs", "flag_green", "flag_mask", "fill")]

mask = np.zeros((5, 7), bool); mask[0, 0] = True
assert dilate(mask, 1).sum() == 3 and not dilate(mask, 1)[-1, -1]
assert nb_sum(np.ones((3, 3), np.float32))[1, 1] == 8
assert nb_sum(np.ones((3, 3), np.float32))[0, 0] == 3
uv = np.array([[[0, 0], [80, 0], [0, 80]], [[1, 1], [1, 1], [1, 1]], [[-2, -2], [-1, -2], [-2, -1]]], float)
covered = raster(uv, range(3), 100, 100)
assert covered[0, 0] and not covered[40, 40]  # no 5% overshoot into adjacent UV islands
assert np.array_equal(covered, raster(uv[:, ::-1], range(3), 100, 100))
assert not raster(uv, [1, 2], 100, 100).any()
assert blobs(np.zeros((3, 7), bool)) == []
pieces = np.zeros((65, 65), bool); pieces[0, 0] = pieces[-1, -1] = True
assert len(blobs(pieces)) == 2

for shape in [(9, 7), (1, 7), (7, 1)]:
    c = np.full((*shape, 3), 0.7, np.float32); known = np.ones(shape, bool)
    known[0, 0] = False; c[0, 0] = 0
    result = pull_push(c, known)
    assert np.isfinite(result).all() and np.allclose(result, 0.7)
    assert np.array_equal(result[known], c[known])
    assert np.array_equal(pull_push(c, np.zeros(shape, bool)), c)

rgb = np.full((96, 128, 3), (0.10, 0.12, 0.25), np.float32)
rgb[25:45, 25:55] = (0.02, 0.5, 0.25)
rgb[30:40, 35:45] = (0.85, 0.05, 0.08)
# Protected details share the texture; include a teal tab directly beside the flag.
rgb[25:45, 55:60] = (0.1, 0.9, 0.8)
rgb[24:46, 20:25] = (0.6, 0.4, 0.3)  # skin
rgb[24:25, 25:55] = (0.95, 0.95, 0.95)  # name tape
rgb[10:20, 70:90] = (0.02, 0.5, 0.25)  # shaded teal, no red disc
rgb[60:70, 25:55] = (0.02, 0.5, 0.25)  # eyes, lips, hair outside garment UVs
rgb[63:67, 35:45] = (0.85, 0.05, 0.08)
near = np.ones(rgb.shape[:2], bool); near[55:] = False
before = rgb.copy()
hole, blueish = flag_mask(rgb, near, 500)
assert hole[30:40, 35:45].all() and hole[25:45, 25:55].all()
assert not hole[25:45, 55:60].any() and not hole[24:46, 20:25].any()
assert not hole[24:25, 25:55].any() and not hole[10:20, 70:90].any() and not hole[55:].any()
fill(rgb, hole, near & ~hole & blueish)
assert np.array_equal(rgb[~hole], before[~hole])
assert not flag_green(rgb[hole]).any() and np.isfinite(rgb).all()

for color in [(0.5, 0.5, 1.0), (0.85, 0.85, 0.85)]:
    for shape in [(17, 23), (8, 11)]:
        arr = np.full((*shape, 3), color, np.float32)
        hole = np.zeros(shape, bool); hole[2:5, 2:5] = True
        arr[hole] = 0
        known = np.zeros(shape, bool); known[1, 1] = True  # sparse donor fallback
        before = arr.copy(); fill(arr, hole, known)
        assert np.allclose(arr[hole], color) and np.array_equal(arr[~hole], before[~hole])
        try:
            fill(arr, hole, np.zeros(shape, bool))
        except ValueError:
            pass
        else:
            raise AssertionError("An empty donor mask must fail before export")

class Node:
    def __init__(self, kind, image=None, inputs=()):
        self.type, self.image, self.inputs = kind, image, inputs

class Socket:
    def __init__(self, node=None):
        self.links = []
        if node is not None:
            link = Node("LINK"); link.from_node = node
            self.links.append(link)

normal = Node("TEX_IMAGE", "normal")
orm = Node("TEX_IMAGE", "orm")
normal_map = Node("NORMAL_MAP", inputs=[Socket(normal)])
split = Node("SEPARATE_COLOR", inputs=[Socket(orm)])
assert scope["linked_images"](Socket(normal_map)) == {"normal"}
assert scope["linked_images"](Socket(split)) == {"orm"}
assert scope["linked_images"](Socket()) == set()

print("PASS add_patches: raster, dilation, neighbours, odd/single-axis fill, components, protected details, map-specific sparse donors, linked maps")
