shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 camera_origin = vec2(0.0);
uniform vec2 viewport_size = vec2(640.0, 360.0);
uniform float fog_strength : hint_range(0.0, 1.0) = 0.13;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.24;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1)), f.x), f.y);
}
void fragment() {
	vec2 pixel = floor(SCREEN_UV * viewport_size);
	vec2 uv = (pixel + 0.5) / viewport_size;
	vec3 col = texture(screen_texture, uv).rgb;
	vec2 world = pixel + camera_origin;
	float mist = noise(world / vec2(115.0, 38.0) + vec2(TIME * 0.035, -TIME * 0.012));
	mist = smoothstep(0.36, 0.85, mist) * fog_strength;
	col = mix(col, vec3(0.42, 0.57, 0.59), mist);
	float edge = smoothstep(0.28, 0.72, length(uv - 0.5));
	col *= 1.0 - edge * vignette_strength;
	// Ordered 2x2 dithering before palette quantization, stable in world space.
	vec2 tile = mod(floor(world), 2.0);
	float dither = (tile.x + tile.y * 2.0) / 4.0 - 0.375;
	col = floor(clamp(col + dither / 48.0, 0.0, 1.0) * 40.0 + 0.5) / 40.0;
	COLOR = vec4(col, 1.0);
}
