#!/usr/bin/env python3
"""素材自检：分辨率 / 帧率 / 编码 / alpha 平面。

用法：
    python tools/check_pack.py characters/bluewhale_tv/videos
    python tools/check_pack.py characters/bluewhale_tv/videos --ffmpeg ffmpeg

需要 ffmpeg（含 libvpx-vp9）。找不到 ffmpeg 时只做文件层面的检查。
退出码 0 = 全部合格，1 = 有问题。
"""
import argparse
import os
import re
import shutil
import subprocess
import sys

EXPECT_W, EXPECT_H, EXPECT_FPS = 640, 360, 24.0


def find_ffmpeg(explicit):
    if explicit:
        return explicit
    found = shutil.which("ffmpeg")
    if found:
        return found
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return None


def stream_info(ffmpeg, path):
    p = subprocess.run([ffmpeg, "-hide_banner", "-i", path], capture_output=True,
                       text=True, encoding="utf-8", errors="replace")
    err = p.stderr
    info = {}
    m = re.search(r"Video:\s*(\w+)[^,]*,\s*(?:([a-z0-9]+)\([^)]*\))?", err)
    if m:
        info["codec"] = m.group(1)
        info["pix_fmt"] = m.group(2) or "?"
    m = re.search(r"(\d{2,5})x(\d{2,5})", err)
    if m:
        info["w"], info["h"] = int(m.group(1)), int(m.group(2))
    m = re.search(r"([\d.]+)\s*fps", err)
    if m:
        info["fps"] = float(m.group(1))
    info["alpha_meta"] = bool(re.search(r"alpha_mode\s*:\s*1", err))
    return info


def has_alpha_pixels(ffmpeg, path):
    """用 libvpx-vp9 解一帧，确认 alpha 平面真的存在（native vp9 解码会丢掉它）。"""
    p = subprocess.run(
        [ffmpeg, "-hide_banner", "-loglevel", "error", "-c:v", "libvpx-vp9", "-i", path,
         "-frames:v", "1", "-pix_fmt", "rgba", "-f", "rawvideo", "-"],
        capture_output=True)
    raw = p.stdout
    if not raw:
        return None
    alphas = raw[3::4]
    return min(alphas) < 250 and max(alphas) > 250


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("directory")
    ap.add_argument("--ffmpeg", default=None)
    args = ap.parse_args()

    root = args.directory
    if not os.path.isdir(root):
        print(f"目录不存在：{root}")
        return 1

    ffmpeg = find_ffmpeg(args.ffmpeg)
    if not ffmpeg:
        print("! 没找到 ffmpeg，只做文件检查。装一个或加 --ffmpeg 指定路径。")

    files = []
    for dirpath, _, names in os.walk(root):
        for n in sorted(names):
            if n.lower().endswith(".webm"):
                files.append(os.path.join(dirpath, n))
    if not files:
        print("没有 .webm 文件。")
        return 1

    problems = 0
    total = 0
    print(f"{'片段':32} {'尺寸':>9} {'fps':>5} {'编码':6} {'alpha':>6}  {'MB':>5}")
    for path in files:
        total += 1
        size_mb = os.path.getsize(path) / 1048576
        name = os.path.relpath(path, root)
        name = (name[:29] + "...") if len(name) > 32 else name
        if not ffmpeg:
            print(f"{name:32} {'-':>9} {'-':>5} {'-':6} {'-':>6} {size_mb:5.2f}")
            continue

        info = stream_info(ffmpeg, path)
        alpha = has_alpha_pixels(ffmpeg, path)
        flags = []
        if (info.get("w"), info.get("h")) != (EXPECT_W, EXPECT_H):
            flags.append(f"尺寸应为 {EXPECT_W}x{EXPECT_H}")
        if abs(info.get("fps", 0) - EXPECT_FPS) > 0.01:
            flags.append(f"帧率应为 {EXPECT_FPS:g}")
        if info.get("codec") != "vp9":
            flags.append("编码应为 vp9")
        if alpha is False:
            flags.append("解不出 alpha 平面")
        if not info.get("alpha_meta"):
            flags.append("缺少 alpha_mode 元数据")

        mark = "OK" if not flags else "FAIL"
        pix = "yes" if alpha else ("no" if alpha is False else "?")
        print(f"{name:32} {info.get('w')}x{info.get('h')} {info.get('fps', 0):5.1f} "
              f"{info.get('codec', '?'):6} {pix:>6}  {size_mb:5.2f}")
        for f in flags:
            print(f"    ! {f}")
            problems += 1
        if flags:
            print(f"    -> {mark}")

    print(f"\n{total} 段，{problems} 处问题。")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
