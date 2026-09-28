# 基础像素精灵

`crowfeather_atlas.png` 使用内置 image_gen 生成，透明 PNG，实际输出尺寸 1254×1254。运行时以 Nearest 采样到低分辨率画布。原图保留透明通道，未重新编码。

图集含 4 列：第一排正面待机、正面左步、正面右步、背面待机；第二排右侧待机、右侧两步、背面步态；第三排路灯、墓碑、木箱、枯树；第四排鸦羽、余烬、钥匙、灌木。左向动画镜像右向帧。

生成模型未严格遵循 1024 网格，第三排道具越过等分行边界。因此 `scripts/pixel/art.gd` 使用实际输出的裁切区域和脚底锚点，避免树根串入物品图标。替换图集后需同步调整裁切参数。

生成方式：内置 image_gen；提示词如下。

> Create a production game sprite atlas for CrowFeather, a melancholic pixel-art 2D game. Output exactly square 1024x1024 transparent PNG. Strict uniform 4 columns x 4 rows grid; each cell 256x256, no grid lines, no lettering, no numbers. Every object centered horizontally, feet/base at y=224 within its cell, leave 24px clear margins. Pixel art with large crisp square pixel clusters, limited 16-color desaturated midnight teal, slate blue, ivory and warm amber palette. Orthographic front-facing 3/4 RPG view (see faces and small top surfaces), not isometric. Row 1 cells: same small hooded crow traveler facing front idle; same front walking left foot forward; same front walking right foot forward; same facing back idle. Row 2 cells: same traveler facing right idle; same facing right walking left foot; same facing right walking right foot; same facing back walking. Traveler has ivory beak-like mask, charcoal feather cloak, tiny ochre scarf, dark boots, readable silhouette, proportions 24x32 logical pixels. Row 3 cells: tall old street lamp with amber glass; gray headstone and a few grass tufts; weathered wooden supply crate; dead crooked tree. Row 4 cells: small black crow feather item; small glowing amber shard item; old iron key item; dark teal bush with pale tips. All 16 cells separate with generous transparent padding, no background scene, no floor plane, no shadows beyond each object, no antialiasing, no gradients, consistent pixel game art. Intended for actual in-game atlas regions.
