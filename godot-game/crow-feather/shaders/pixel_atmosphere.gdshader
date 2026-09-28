shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 camera_origin=vec2(0.0);
uniform vec2 viewport_size=vec2(960.0,540.0);
uniform vec3 fog_color : source_color=vec3(0.42,0.57,0.59);
uniform float fog_strength=0.2;
uniform float vignette_strength=0.22;
uniform float motion_clock=0.0;
uniform float ritual=0.0;
uniform bool gentle=true;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void fragment(){
	vec2 pixel=floor(SCREEN_UV*viewport_size);
	vec2 uv=(pixel+0.5)/viewport_size;
	vec3 col=texture(screen_texture,uv).rgb;
	col=mix(col,col*(fog_color*0.65+vec3(0.62)),0.7);
	vec2 world=pixel+camera_origin;
	float mist=smoothstep(0.25,0.8,noise(world/vec2(155.0,56.0)+vec2(motion_clock*0.025,-motion_clock*0.01)));
	float amount=mist*fog_strength;
	float ring=smoothstep(0.08,0.4,length(uv-vec2(0.5,0.55)));
	amount+=ritual*ring*(gentle?0.0:0.78);
	col=mix(col,fog_color,clamp(amount,0.0,0.86));
	col*=1.0-smoothstep(0.25,0.73,length(uv-0.5))*vignette_strength;
	COLOR=vec4(col,1.0);
}