# 素材许可与出处（Visual asset notice）

本仓库的**动画素材**与**脚本**不是同一个许可，分开写清楚，别混着抄。

## 1. 动画素材：CC BY-NC-SA 4.0

`characters/bluewhale_tv/` 下的全部 `.webm` 动画与三个 `.json` 配置，以
[Creative Commons 署名—非商业性使用—相同方式共享 4.0 国际](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh-hans)
（CC BY-NC-SA 4.0）发布。法律全文见仓库根目录的 [LICENSE](LICENSE)，
在线版 <https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.txt>。

你可以：

- 自由下载、使用、剪辑、改色、改动作、拿去当自己的桌宠角色；
- 二次发布（包括打包进你自己的角色包 / 插件）。

条件：

1. **署名**：保留下面第 3 节的完整署名链，并在你的 README、发布页或产品说明里给出本仓库链接与
   CC BY-NC-SA 4.0 的链接。删署名再发布 = 违规。
2. **非商业**：不得用于任何以营利为主要目的的场景 —— 付费资源包、会员专享、付费课程附赠、
   随硬件或服务搭售、广告投放素材、接单交付，都算。
3. **相同方式共享**：你基于这些素材做的改编（重绘、换色、加动作、重编码），发布时必须用
   同样的 CC BY-NC-SA 4.0（或 CC 认可的同元素兼容许可）发布，不能改成更严格的条款。

## 2. 脚本：MIT

`install.ps1`、`tools/` 下的 Python 脚本，以 MIT 许可发布，见 [LICENSES/MIT.txt](LICENSES/MIT.txt)。
随便改、随便用、随便商用，保留版权声明即可。

## 3. 署名链（二次发布必须原样保留）

本角色是独立创作，**参考了**社区「大肥鱼 / 鲸鱼娘」的人物设计语言，但不是同一个人物。
为免争议，本仓库仍保留完整的设计参考署名，并按来源惯例以 CC BY-NC-SA 4.0 发布：

- **桌宠运行时**：[`PC2005-cloud/dsh-pet`](https://github.com/PC2005-cloud/dsh-pet)（MIT）、
  [`MerZlin/dsh-pet-indesktop`](https://github.com/MerZlin/dsh-pet-indesktop)（MIT）。
  素材目录格式、`manifest.json` 与 `move_strides.json` 的约定都来自这两个项目。
- **形象原型「溟月」**：B 站 [@上善无形](https://space.bilibili.com/4456176)。
- **DeepSeek 版女仆鲸鱼娘形象设计**：B 站 [@ZipZipPipe](https://space.bilibili.com/4168597)。
- **形象授权声明原文**：<https://www.bilibili.com/opus/1247156596114456581>
  —— 「大肥鱼是遵守 CC BY-NC-SA 4.0 协议的形象，不可以以任何形式商业化。」
- **本套动画**：AI 视频生成（绿幕源）→ 抠像 → 裁切 → 640×360 VP9-alpha 转码。
  动画的剪辑、转码与打包工作由本仓库作者完成。

## 4. 关于 AI 生成

源片由 AI 视频模型生成后经脚本处理。发布者已按所用服务商的条款使用其输出；
**下游使用者仍需自行确认**：你所在地区对 AI 生成内容的可版权性认定不同，
本许可只覆盖发布者能许可的部分（剪辑、合成、转码这些劳动成果），不构成对
「AI 原始输出是否享有版权」的保证。

## 5. 不提供担保

素材按「现状」提供，不附带任何明示或默示担保。用于直播、录屏、商业展示前请自行测试。
