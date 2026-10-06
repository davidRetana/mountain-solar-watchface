"""Generate native-size, symmetric MIP glyphs without scaling or antialiasing."""

from pathlib import Path
import struct
import zlib


PIN = (
    "...###...",
    ".#######.",
    "###...###",
    "##.....##",
    "##.....##",
    "###...###",
    ".#######.",
    ".#######.",
    "..#####..",
    "..#####..",
    "...###...",
    "...###...",
    "....#....",
    "....#....",
)

THERMOMETER = (
    ".....###.....",
    "....#...#....",
    "....#...#....",
    "....#...#....",
    "....#.#.#....",
    "....#.#.#....",
    "....#.#.#....",
    "....#.#.#....",
    "....#.#.#....",
    "....#.#.#....",
    "....#.#.#....",
    "...#..#..#...",
    "..#..###..#..",
    "..#.#####.#..",
    "..#..###..#..",
    "...#.....#...",
    "....#####....",
)


def write_png(path, rows):
    width = len(rows[0])
    assert all(len(row) == width for row in rows)

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data)))

    # Two native MIP colors: black background and Theme.MUTED (0xAAAAAA).
    pixels = b"".join(b"\0" + bytes(170 if p == "#" else 0 for p in row)
                      for row in rows)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, len(rows), 8, 0, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(pixels))
        + chunk(b"IEND", b"")
    )


if __name__ == "__main__":
    output = Path(__file__).resolve().parents[1] / "resources" / "drawables"
    for name, rows in (("location_icon", PIN), ("thermometer_icon", THERMOMETER)):
        assert all(row == row[::-1] for row in rows), name
        write_png(output / f"{name}.png", rows)
