shader_type canvas_item;
render_mode unshaded;
uniform float warm_light : hint_range(0.0,1.0)=0.0;
uniform bool gentle=true;
void fragment(){
	vec4 tex=texture(TEXTURE,UV);
	vec3 cold=gentle?vec3(0.27,0.49,0.59):vec3(0.48,0.78,0.91);
	COLOR=vec4(mix(max(tex.rgb,cold*0.55),vec3(0.015,0.019,0.027),warm_light),tex.a);
}