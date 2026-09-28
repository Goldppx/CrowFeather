shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 camera_origin=vec2(0.0);
uniform vec2 viewport_size=vec2(960.0,540.0);
uniform vec3 fog_color : source_color=vec3(0.42,0.57,0.59);
uniform float fog_strength=0.2;
uniform float vignette_strength=0.20;
uniform float motion_clock=0.0;
uniform float ritual=0.0;
uniform bool gentle=true;
uniform float rain_amount=0.4;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void fragment(){
	// A stable coarse pixel grid makes weather agree with the low-resolution sprites.
	vec2 pixel=floor(SCREEN_UV*viewport_size/2.0)*2.0;
	vec2 uv=(pixel+1.0)/viewport_size;
	vec3 col=texture(screen_texture,SCREEN_UV).rgb;
	vec2 world=pixel+camera_origin;
	float low=noise(world/vec2(180.0,55.0)+vec2(motion_clock*0.024,-motion_clock*0.009));
	float high=noise(world/vec2(310.0,100.0)-vec2(motion_clock*0.012,0.0));
	float mist=smoothstep(0.26,0.79,low*0.65+high*0.35);
	float amount=mist*fog_strength;
	float ring=smoothstep(0.08,0.4,length(uv-vec2(0.5,0.55)));
	amount+=ritual*ring*(gentle?0.0:0.55);
	col=mix(col,fog_color,clamp(amount,0.0,0.78));
	// Two deterministic diagonal rain layers, no lightning or high-frequency flashing.
	for(int layer=0;layer<2;layer++){
		float depth=1.0+float(layer)*0.5;
		vec2 p=pixel*depth+vec2(motion_clock*37.0,-motion_clock*210.0);
		p.x+=p.y*0.14;
		vec2 cell=floor(p/vec2(21.0,85.0));
		vec2 local=mod(p,vec2(21.0,85.0));
		float drop=step(hash(cell),rain_amount*0.52)*step(local.x,1.5)*step(local.y,7.0);
		col=mix(col,vec3(0.59,0.70,0.77),drop*(0.24-float(layer)*0.07));
	}
	vec2 puddle=floor(world/vec2(36.0,24.0));
	float phase=fract(motion_clock*1.4+hash(puddle)*9.0);
	vec2 local=fract(world/vec2(36.0,24.0))-0.5;
	float ripple=step(abs(length(local*vec2(1.0,2.5))-phase*0.34),0.03)*(1.0-phase);
	ripple*=step(hash(puddle+3.0),rain_amount*0.3)*step(0.61,uv.y);
	col=mix(col,vec3(0.4,0.52,0.6),ripple*0.22);
	col*=1.0-smoothstep(0.25,0.73,length(uv-0.5))*vignette_strength;
	COLOR=vec4(col,1.0);
}