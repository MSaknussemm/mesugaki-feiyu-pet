# 更新记录

## v1.0.0 — 2026-10-29

首次发布。

- 47 段动画：`idle` 6 / `random` 29 / `click` 8 / `move` 2 / `turn` 1 / `drag` 1
- 全部 640×360、24 fps、VP9 Profile 0、`yuva420p`（alpha_mode=1）
- `manifest.json`：`body_box [220,16,420,351]`、`head_box [214,16,426,156]`
- `move_strides.json`：`漂浮踏步` stride 90、`左转奔跑` stride 220，附 240 点线性位移曲线
- 走 / 跑做过步态重剪：抽掉原片的静止段，按真实步态循环，消除「走两步顿一下」
- `打游戏` 改为乒乓循环（正放 + 倒放），消除首尾姿态不匹配造成的闪跳
- Windows 安装脚本 `install.ps1`：自动定位安装目录、备份旧角色、支持 `-Uninstall` 还原
- 素材自检脚本 `tools/check_pack.py`
