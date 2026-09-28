# 美术资源与生成记录

本轮使用原生 image_gen 工具绘制透明 PNG 图集，再由 Godot art_bank.gd 按角色行边界裁切、自动裁去透明边缘，最近邻显示。没有用程序几何图形替代角色绘制。

## 文件

均位于 godot-game/crow-feather/art/characters/：deer.png、horse.png、pig.png、sheep.png、chicken.png 包含站立 / 对话 / 行走 / 死亡 / 墓碑与下方高分辨率遗体特写；player.png 为方向步态、站立与跪地；crow.png 为飞行周期；menu.png 为墓园背景。

主角后续编辑固定提灯在同一只手；马人后续编辑明确三条腿。墓园以仓库 assets/images/宣传图海报.jpg 为参考。现有道具与地面仍复用 art/pixel 图集，与新人物图集共同组成原型场景。

字体 art/fonts/NotoSansSC.ttf 来自 google/fonts 的 ofl/notosanssc，许可证同目录 OFL.txt。字体显示层使用可变字重与轻微加粗，与世界像素采样独立。

## 原始生成提示词

### deer.png

```text
Create one production-ready transparent PNG game sprite atlas for CrowFeather, an atmospheric dark 2D pixel-art narrative game. Square 1024x1024 image. Subject: a slender anthropomorphic DEER-headed village mourner, branching antlers, dark moss green Victorian coat, pale amber eyes, locket, humane melancholy silhouette. Tasteful hand-crafted detailed pixel art, limited muted night palette with warm accents, crisp stepped edges, no painterly blur, no text, no grid lines, no background, real alpha transparency. STRICT ATLAS LAYOUT: TOP HALF is exactly 4 equal columns x 2 equal rows, each tile 256x256. Same consistent orthographic frontal three-quarter character, identical size and ground baseline y=232 within every tile, with large clear margins; never spill outside tiles. Top row left to right: idle standing, speaking with small expressive gesture, walking left-foot forward contact, walking passing pose. Second row: walking right-foot forward contact, opposite passing pose, falling peacefully to knees death animation pose, an individual gothic gravestone with recognizable deer emblem. BOTTOM HALF (y=512..1023) is ONE large detailed 1024x512 corpse inspection illustration: the same character lying peacefully on side, full body horizontal, closed eyes, personal relic beside it, no blood or gore, transparent background and generous margins, higher detailed pixel art suitable for an enlarged inspection window. All eight top tiles and the single bottom corpse image must be isolated and separable. Maintain character clothing identity throughout.
```

### horse.png

```text
Create one production-ready transparent PNG game sprite atlas for CrowFeather, an atmospheric dark 2D pixel-art narrative game. Square 1024x1024 image. Subject: an anthropomorphic HORSE messenger with THREE legs visible as his distinctive silhouette, chestnut horse head, worn indigo postman's coat, leather letter satchel, tired friendly face. Tasteful hand-crafted detailed pixel art, limited muted night palette with warm accents, crisp stepped edges, no painterly blur, no text, no grid lines, no background, real alpha transparency. STRICT ATLAS LAYOUT: TOP HALF is exactly 4 equal columns x 2 equal rows, each tile 256x256. Same consistent orthographic frontal three-quarter character, identical size and ground baseline y=232 within every tile, with large clear margins; never spill outside tiles. Top row left to right: idle standing, speaking with small expressive gesture, walking left-foot forward contact, walking passing pose. Second row: walking right-foot forward contact, opposite passing pose, falling peacefully to knees death animation pose, an individual gothic gravestone with recognizable horse emblem. BOTTOM HALF (y=512..1023) is ONE large detailed 1024x512 corpse inspection illustration: the same character lying peacefully on side, full body horizontal, closed eyes, personal relic beside it, no blood or gore, transparent background and generous margins, higher detailed pixel art suitable for an enlarged inspection window. All eight top tiles and the single bottom corpse image must be isolated and separable. Maintain character clothing identity throughout.
```

### pig.png

```text
Create one production-ready transparent PNG game sprite atlas for CrowFeather, an atmospheric dark 2D pixel-art narrative game. Square 1024x1024 image. Subject: a stocky PIG-headed butcher villager, burgundy waistcoat and leather apron, ivory tusks small, tarnished brass watch. Tasteful hand-crafted detailed pixel art, limited muted night palette with warm accents, crisp stepped edges, no painterly blur, no text, no grid lines, no background, real alpha transparency. STRICT ATLAS LAYOUT: TOP HALF is exactly 4 equal columns x 2 equal rows, each tile 256x256. Same consistent orthographic frontal three-quarter character, identical size and ground baseline y=232 within every tile, with large clear margins; never spill outside tiles. Top row left to right: idle standing, speaking with small expressive gesture, walking left-foot forward contact, walking passing pose. Second row: walking right-foot forward contact, opposite passing pose, falling peacefully to knees death animation pose, an individual gothic gravestone with recognizable pig emblem. BOTTOM HALF (y=512..1023) is ONE large detailed 1024x512 corpse inspection illustration: the same character lying peacefully on side, full body horizontal, closed eyes, personal relic beside it, no blood or gore, transparent background and generous margins, higher detailed pixel art suitable for an enlarged inspection window. All eight top tiles and the single bottom corpse image must be isolated and separable. Maintain character clothing identity throughout.
```

### sheep.png

```text
Create one production-ready transparent PNG game sprite atlas for CrowFeather, an atmospheric dark 2D pixel-art narrative game. Square 1024x1024 image. Subject: a thin SHEEP-headed villager, curling horns, cream wool head, ash blue long shawl and old grey dress, small bell. Tasteful hand-crafted detailed pixel art, limited muted night palette with warm accents, crisp stepped edges, no painterly blur, no text, no grid lines, no background, real alpha transparency. STRICT ATLAS LAYOUT: TOP HALF is exactly 4 equal columns x 2 equal rows, each tile 256x256. Same consistent orthographic frontal three-quarter character, identical size and ground baseline y=232 within every tile, with large clear margins; never spill outside tiles. Top row left to right: idle standing, speaking with small expressive gesture, walking left-foot forward contact, walking passing pose. Second row: walking right-foot forward contact, opposite passing pose, falling peacefully to knees death animation pose, an individual gothic gravestone with recognizable sheep emblem. BOTTOM HALF (y=512..1023) is ONE large detailed 1024x512 corpse inspection illustration: the same character lying peacefully on side, full body horizontal, closed eyes, personal relic beside it, no blood or gore, transparent background and generous margins, higher detailed pixel art suitable for an enlarged inspection window. All eight top tiles and the single bottom corpse image must be isolated and separable. Maintain character clothing identity throughout.
```

### chicken.png

```text
Create one production-ready transparent PNG game sprite atlas for CrowFeather, an atmospheric dark 2D pixel-art narrative game. Square 1024x1024 image. Subject: an ordinary nonanthropomorphic CHICKEN, strictly a real quadruped-form bird with TWO legs, red comb, ochre and ivory feathers, small black eyes; absolutely no human torso, arms, hands or clothes. Tasteful hand-crafted detailed pixel art, limited muted night palette with warm accents, crisp stepped edges, no painterly blur, no text, no grid lines, no background, real alpha transparency. STRICT ATLAS LAYOUT: TOP HALF is exactly 4 equal columns x 2 equal rows, each tile 256x256. Same consistent orthographic frontal three-quarter character, identical size and ground baseline y=232 within every tile, with large clear margins; never spill outside tiles. Top row left to right: idle standing, speaking with small expressive gesture, walking left-foot forward contact, walking passing pose. Second row: walking right-foot forward contact, opposite passing pose, falling peacefully to knees death animation pose, an individual gothic gravestone with recognizable chicken emblem. BOTTOM HALF (y=512..1023) is ONE large detailed 1024x512 corpse inspection illustration: the same character lying peacefully on side, full body horizontal, closed eyes, personal relic beside it, no blood or gore, transparent background and generous margins, higher detailed pixel art suitable for an enlarged inspection window. All eight top tiles and the single bottom corpse image must be isolated and separable. Maintain character clothing identity throughout.
```

### player.png

```text
Production-ready transparent PNG sprite atlas, square 1024x1024, EXACT 4 columns x4 rows, each cell256x256, no text no grid no background real transparent alpha. One consistent 2D pixel-art crow-feather undertaker protagonist: tall slender black feather cloak, bird-like beaked hood, pale beak pointing clearly forward, small warm amber lantern in right hand. Crisp detailed hand-crafted pixel art in limited navy charcoal teal amber palette. Orthographic 2.5D game sprites, upright frontal/side camera (not top-down). ALL figures have identical scale within256px cells, feet baseline at cell y232, top at y35, centered x128, no protrusions outside cell. Row 1 front-facing walking cycle four distinct frames: left foot forward contact, passing raised heel, right foot forward contact, opposite passing. Row2 back-facing walking same four distinct foot phases. Row3 facing right side walking same four distinct foot phases. Row4: front idle, back idle, right idle, front kneeling investigating a body. Coat skirt and lantern follow the foot motion subtly, limbs move with anatomical consistency. Feet stay firmly on baseline, no whole-body lateral drift. Silhouette immediately readable, lantern small warm light but no large blurry glow. This is functional game animation, each frame independent and isolated.
```

### crow.png

```text
Transparent PNG square1024x1024 game sprite atlas, EXACT 4 columns x2 rows (each cell256 wide512 high). Eight successive wing beats of the SAME small black raven flying to the right, cohesive loop: wings extended up, diagonally up, horizontal, down, down most, lifting, horizontal, up. Each crow centered in its cell at x128,y256, same body position and same scale, wings and tail fully contained. Crisp detailed pixel art, blue black feathers with subtle icy cyan outline, tiny cyan eye. No environment, no words, no grid, real alpha. Flight silhouette intended to become pure black below warm streetlamps. Usable as Sprite2D animation frames.
```

### menu.png

```text
Create a wide 16:9 background plate for a playable pixel-art cemetery title screen of CrowFeather. Inspired by the provided atmosphere reference only: deep indigo night, cyan mist, warm amber gothic streetlamps, distant towering Victorian silhouettes, black iron fences and skeletal trees, a few tiny luminous crow silhouettes above. Hand-crafted detailed pixel art, restrained palette and deliberate crisp pixel clusters. Orthographic frontal 2.5D game perspective: ground in bottom two thirds is walkable broad mossy cobblestone cemetery courtyard, deliberately open central area for separately placed character and three save gravestones; don't draw gravestones or people into this background. Background buildings and trees occupy the top third. One tall lamp at far left and one at far right, atmospheric visual depth. NO words, NO logo, NO lettering, NO interface. Dark but readable ground, no bloom glare, non-photorealistic. Wide composition suitable for stretching behind a 2D game level.
```

## 后续修改要求

- player.png：保持所有步态帧的提灯手一致，避免交替换手；保留透明背景、布局和服饰。
- horse.png：遵循角色文档的三条腿，站立、行走、死亡、遗体特写一致。

原生工具输出经人工查看后复制至上述项目路径；游戏内墓园、触屏布局、特写和设置截图见 docs/previews。插图分辨率高于屏幕中的角色显示尺寸，后续仍可进一步逐帧手工修整步态。
