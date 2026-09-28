# CrowFeather development

- 永远不要用 astra 模型。
- 当前游戏方向为 2D 像素风、正视角 2.5D 地面移动；主场景为 `scenes/PixelMain.tscn`。旧 lowpoly / 第一人称 3D 内容仅作为历史素材保留。
- Godot 项目位于 `godot-game/crow-feather`，使用 Godot 4.6.3 编辑。不要用 4.7 打开并保存此项目，除非明确决定升级。
- 后续 Godot 场景、节点、脚本及运行状态的开发和检查优先使用已配置的 `godot-crowfeather` MCP。使用前以 Godot 编辑器打开项目，确认 MCP 的 `get_project_info` 能返回项目名称 `CrowFeather`。
- 仓库中的 `addons/godot_mcp` 是编辑器端插件；本机 MCP 服务端通过 Codex 的 `~/.codex/config.toml` 启动。
