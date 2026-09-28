shader_type canvas_item;
uniform float motion_clock = 0.0;
render_mode unshaded;
uniform vec4 deep_color : source_color = vec4(0.055, 0.15, 0.19, 1.0);
uniform vec4 ripple_color : source_color = vec4(0.18, 0.32, 0.35, 1.0);
void fragment() {
	vec2 p = floor(UV * vec2(170.0, 74.0));
	float wave = sin(p.x * 0.12 + p.y * 0.6 + motion_clock * 0.8);
	float streak = step(0.92, wave) * step(0.5, sin(p.y * 2.7));
	float edge = smoothstep(0.15, 0.5, abs(UV.y - 0.5));
	COLOR = mix(deep_color, ripple_color, streak * 0.55 + edge * 0.14);
}
