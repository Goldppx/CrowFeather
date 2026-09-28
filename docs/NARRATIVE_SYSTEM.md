# 剧情、存档和 Agent 扩展

## 概念对应

依据 概念/大略开发方向.md、雾.md、尸体.md、头顶的乌鸦.md 与第一章序幕：夜晚暖灯与冷雾、遗物调查、顺应死亡或抹去存在、因果消失、角色重要性驱动畸变、漏斗式分支回归。马人保留三条腿，新鹿头人不替代原长颈鹿。

scripts/pixel/story.gd 定义角色、区域、权重、裁决。data/story_graph.json 定义标题、文本、候选边和条件。world.gd 根据因果标记显示信箱、集市、钟。新增文案为可替换样章。

## 扩展剧情

节点格式：
```json
{"title":"标题","text":"文本","edges":[{"to":"next","flag":"mail_route","equals":true}]}
```

无条件边省略 flag / equals。先添加目标节点，再添加来源边；available() 筛条件，advance() 拒绝非法跳转。局部分支末端共同指向回归节点，保留此前 flags。

现有路径：来信 → 鹿头人调查 → 无名庭院 / 留名 → 歧路 → 来信 / 沉默 → 钟坡汇合 → 自己的实体。五个裁决完成后开放最终节点。极端抹去、极端顺应、混合路径已有结局分类，完整结局演出尚未制作。

judge() 幂等，每名角色只裁决一次。裁决立即存盘，动画中断不撤销选择。区域、背包、遗物、剧情共享槽位快照。存档 version=1；未来不兼容改动应提供显式迁移。

## DeepSeek 接口（默认离线）

director.gd 生成关键节点上下文和 JSON 请求体：request_id、当前节点、allowed_nodes、裁决统计、flags、最近 12 次动作。模型只能选择合法边，不能推翻玩家裁决。

deepseek_adapter.gd 是异步 HTTPRequest 传输层。enabled=false，endpoint / model 为空；当前构建不请求 DeepSeek、不包含 API key。后续接入由可信后端保管密钥并转发，客户端配置后端 HTTPS 地址与模型。后端认证、配额和部署属于后续接入工作。

配置 world.adapter.endpoint、.model、.enabled=true 后，手记继续按钮通过 request_story_step() 发请求。后端可直接返回：
```json
{"request_id":1,"node":"合法节点","reason":"简短理由"}
```

也支持标准聊天 envelope，choices[0].message.content 为上述 JSON 字符串。8 秒超时；断网、错误状态、无效 JSON、过大响应、非法节点均回退本地合法边。回包重新校验槽位、房间、节点，过期忽略；切换房间取消请求。测试器可注入合法 / 非法建议。

使用 JSON mode 并明确提示 JSON 输出，部署时再选择官方支持的模型：
[DeepSeek JSON mode](https://api-docs.deepseek.com/guides/json_mode/)、
[聊天接口](https://api-docs.deepseek.com/api/create-chat-completion/)。

## 模块边界

| 模块 | 职责 |
| --- | --- |
| save_store.gd | 三槽、验证、临时替换、备份、沙盒 |
| settings.gd | 设置、音频总线、桌面窗口 |
| world.gd / ground.gd | 旅程状态 / 地面与碰撞 |
| character.gd / art_bank.gd | 动画 / 图集裁切、遗体 |
| hud.gd | 所有窗口、测试器、触控 |
| director.gd / deepseek_adapter.gd | 建议校验 / 可选传输 |

DEV 使用 slot=0 和 sandbox=true 双重保护；真实槽位仅接受 1–3。测试不覆盖真实存档。
