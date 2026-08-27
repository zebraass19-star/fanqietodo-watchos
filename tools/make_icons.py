#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成番茄钟 App 的全部 watchOS 图标 PNG（黑底 + Ultra 橙进度环）。
纯标准库实现（zlib/struct），无需安装任何第三方包。
用法：python tools/make_icons.py
"""

import math
import os
import struct
import zlib

ORANGE = (255, 96, 0)   # Apple Watch Ultra 橙 #FF6000
BLACK = (0, 0, 0)

# 文件名 -> 像素尺寸（与 AppIcon.appiconset/Contents.json 一一对应）
ICONS = [
    ("icon-24@2x.png", 48),
    ("icon-27.5@2x.png", 55),
    ("icon-29@2x.png", 58),
    ("icon-29@3x.png", 87),
    ("icon-40@2x.png", 80),
    ("icon-44@2x.png", 88),
    ("icon-46@2x.png", 92),
    ("icon-50@2x.png", 100),
    ("icon-51@2x.png", 102),
    ("icon-54@2x.png", 108),
    ("icon-86@2x.png", 172),
    ("icon-98@2x.png", 196),
    ("icon-108@2x.png", 216),
    ("icon-117@2x.png", 234),
    ("icon-129@2x.png", 258),
    ("icon-1024.png", 1024),
]

ARC_FRACTION = 0.75  # 圆环覆盖 3/4 圈（模拟进度环，留 1/4 缺口）


def render(size):
    """渲染 size x size 的 RGBA 图：黑底 + 橙色进度环。"""
    ss = 4 if size < 256 else 2  # 超采样倍数（大图用 2 倍控制耗时）
    S = size * ss
    cx = cy = S / 2.0
    radius = S * 0.40
    half_w = max(1.5, S * 0.055 / 2.0)
    arc_limit = ARC_FRACTION * 2.0 * math.pi

    buf = [bytearray(S * 4) for _ in range(S)]  # 每像素 4 字节 RGBA，初始黑
    for y in range(S):
        row = buf[y]
        dy = y + 0.5 - cy
        for x in range(S):
            dx = x + 0.5 - cx
            d = math.hypot(dx, dy)
            if abs(d - radius) > half_w:
                continue
            # 角度：从 12 点方向顺时针
            theta = math.atan2(dx, -dy)
            if theta < 0.0:
                theta += 2.0 * math.pi
            if theta <= arc_limit:
                i = x * 4
                row[i] = ORANGE[0]
                row[i + 1] = ORANGE[1]
                row[i + 2] = ORANGE[2]
                row[i + 3] = 255

    # 盒式降采样回目标尺寸
    out = []
    for y in range(size):
        row = bytearray(size * 4)
        for x in range(size):
            r = g = b = 0
            for yy in range(ss):
                src = buf[y * ss + yy]
                for xx in range(ss):
                    i = (x * ss + xx) * 4
                    r += src[i]
                    g += src[i + 1]
                    b += src[i + 2]
            n = ss * ss
            i = x * 4
            row[i] = r // n
            row[i + 1] = g // n
            row[i + 2] = b // n
            row[i + 3] = 255
        out.append(bytes(row))
    return out


def _chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


def write_png(path, width, height, rgba_rows):
    raw = b"".join(b"\x00" + row for row in rgba_rows)
    png = (b"\x89PNG\r\n\x1a\n"
           + _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
           + _chunk(b"IDAT", zlib.compress(raw, 9))
           + _chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def main():
    out_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "PomodoroWatch", "Assets.xcassets", "AppIcon.appiconset")
    out_dir = os.path.normpath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    for name, size in ICONS:
        path = os.path.join(out_dir, name)
        rows = render(size)
        write_png(path, size, size, rows)
        print(f"OK  {name}  ({size}x{size})")
    print(f"共生成 {len(ICONS)} 个图标 -> {out_dir}")


if __name__ == "__main__":
    main()
