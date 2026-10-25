#!/usr/bin/env python3
"""Render Muster's image assets from docs/assets/logo.svg.

    python3 scripts/render-assets.py

Writes:
  docs/assets/social-preview.png   1280x640, the GitHub social card
  docs/assets/favicon-32.png       browser tab icon
  docs/assets/apple-touch-icon.png 180x180, home-screen icon
  docs/favicon.ico                 16/32/48 px, for browsers that ask for /favicon.ico
  Muster/Media/muster.tga          64x64, the in-game icon (3.3.5 loads TGA)

Needs librsvg and cairo (packages librsvg2-2 and libcairo2 on Debian/Ubuntu);
it calls them through ctypes, so there is nothing to pip install.
"""
import ctypes
import os
import struct
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "docs", "assets")

rsvg = ctypes.CDLL("librsvg-2.so.2")
cairo = ctypes.CDLL("libcairo.so.2")


class Rect(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double),
                ("width", ctypes.c_double), ("height", ctypes.c_double)]


rsvg.rsvg_handle_new_from_file.restype = ctypes.c_void_p
rsvg.rsvg_handle_new_from_file.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
rsvg.rsvg_handle_render_document.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(Rect), ctypes.c_void_p]
cairo.cairo_image_surface_create.restype = ctypes.c_void_p
cairo.cairo_create.restype = ctypes.c_void_p
cairo.cairo_create.argtypes = [ctypes.c_void_p]
cairo.cairo_destroy.argtypes = [ctypes.c_void_p]
cairo.cairo_surface_flush.argtypes = [ctypes.c_void_p]
cairo.cairo_surface_destroy.argtypes = [ctypes.c_void_p]
cairo.cairo_surface_write_to_png.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
cairo.cairo_image_surface_get_data.restype = ctypes.POINTER(ctypes.c_ubyte)
cairo.cairo_image_surface_get_data.argtypes = [ctypes.c_void_p]
cairo.cairo_image_surface_get_stride.argtypes = [ctypes.c_void_p]


def render(svg_path, width, height):
    """Return a cairo ARGB32 surface with the SVG drawn at width x height."""
    handle = rsvg.rsvg_handle_new_from_file(svg_path.encode(), None)
    if not handle:
        raise SystemExit("could not load " + svg_path)
    surface = cairo.cairo_image_surface_create(0, width, height)  # CAIRO_FORMAT_ARGB32
    cr = cairo.cairo_create(surface)
    if not rsvg.rsvg_handle_render_document(handle, cr, ctypes.byref(Rect(0, 0, width, height)), None):
        raise SystemExit("could not render " + svg_path)
    cairo.cairo_destroy(cr)
    cairo.cairo_surface_flush(surface)
    return surface


def write_png(svg_path, out, width, height):
    surface = render(svg_path, width, height)
    if cairo.cairo_surface_write_to_png(surface, out.encode()) != 0:
        raise SystemExit("could not write " + out)
    cairo.cairo_surface_destroy(surface)
    print("wrote", os.path.relpath(out, ROOT))


def png_bytes(svg_path, size):
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        path = tmp.name
    try:
        surface = render(svg_path, size, size)
        cairo.cairo_surface_write_to_png(surface, path.encode())
        cairo.cairo_surface_destroy(surface)
        with open(path, "rb") as f:
            return f.read()
    finally:
        os.unlink(path)


def write_ico(svg_path, out, sizes=(16, 32, 48)):
    """An .ico whose entries are PNGs, which every current browser reads."""
    images = [png_bytes(svg_path, s) for s in sizes]
    header = struct.pack("<HHH", 0, 1, len(images))
    offset = len(header) + 16 * len(images)
    entries, data = b"", b""
    for size, img in zip(sizes, images):
        entries += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(img), offset)
        offset += len(img)
        data += img
    with open(out, "wb") as f:
        f.write(header + entries + data)
    print("wrote", os.path.relpath(out, ROOT))


def write_tga(svg_path, out, size):
    """Uncompressed 32-bit TGA, bottom-left origin, straight alpha: what the 3.3.5 client loads."""
    surface = render(svg_path, size, size)
    stride = cairo.cairo_image_surface_get_stride(surface)
    raw = ctypes.string_at(cairo.cairo_image_surface_get_data(surface), stride * size)
    pixels = bytearray()
    for y in range(size - 1, -1, -1):  # TGA rows go bottom to top
        row = raw[y * stride:y * stride + size * 4]
        for x in range(size):
            b, g, r, a = row[x * 4:x * 4 + 4]  # cairo ARGB32 is BGRA in memory, premultiplied
            if a:
                b, g, r = (min(255, c * 255 // a) for c in (b, g, r))
            pixels += bytes((b, g, r, a))
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 8)
    with open(out, "wb") as f:
        f.write(header + bytes(pixels))
    cairo.cairo_surface_destroy(surface)
    print("wrote", os.path.relpath(out, ROOT))


def main():
    logo = os.path.join(ASSETS, "logo.svg")

    # The social card embeds the logo; splice its drawing into the template.
    with open(logo) as f:
        body = f.read()
    body = body[body.index(">", body.index("<svg")) + 1:body.rindex("</svg>")]
    with open(os.path.join(ASSETS, "social-preview.svg")) as f:
        card = f.read().replace("LOGO_BODY", body)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as tmp:
        tmp.write(card)
        card_path = tmp.name
    try:
        write_png(card_path, os.path.join(ASSETS, "social-preview.png"), 1280, 640)
    finally:
        os.unlink(card_path)

    write_png(logo, os.path.join(ASSETS, "favicon-32.png"), 32, 32)
    write_png(logo, os.path.join(ASSETS, "apple-touch-icon.png"), 180, 180)
    write_ico(logo, os.path.join(ROOT, "docs", "favicon.ico"))
    write_tga(logo, os.path.join(ROOT, "Muster", "Media", "muster.tga"), 64)


if __name__ == "__main__":
    main()
