shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform bool gentle = true;
uniform vec4 actor_tint : source_color=vec4(1.0);
float hash(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
void fragment(){
	vec4 tex=texture(TEXTURE,UV);
	float noise=hash(floor(UV*vec2(80.0,100.0)));
	float field=UV.y*0.55+noise*0.45;
	float threshold=progress*1.12-0.06;
	float remain=smoothstep(threshold,threshold+0.04,field);
	float rim=(1.0-smoothstep(threshold+0.035,threshold+0.11,field))*remain;
	vec3 glow=gentle?vec3(0.5,0.65,0.65):vec3(0.8,0.9,0.83);
	vec3 color=mix(tex.rgb,glow,rim*(gentle?0.0:0.95));
	COLOR=vec4(color,tex.a*remain)*actor_tint;
}