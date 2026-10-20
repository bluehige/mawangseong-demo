shader_type canvas_item;
render_mode unshaded;
uniform vec2 packed_depth;
void fragment() {
	float alpha = texture(TEXTURE,UV).a;
	if (alpha < 0.1) discard;
	COLOR = vec4(packed_depth,0.0,1.0);
}
