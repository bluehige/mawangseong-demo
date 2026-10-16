shader_type canvas_item;
render_mode unshaded;
uniform sampler2D wall_depth : filter_nearest, repeat_disable;
uniform vec2 wall_origin;
uniform vec2 wall_size;
uniform float foot_depth;
uniform vec4 silhouette_color : source_color;
uniform bool chroma_key = false;
uniform vec3 map_x;
uniform vec3 map_y;
varying vec2 map_position;
void vertex() {
	vec3 world = vec3((MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy,1.0);
	map_position = vec2(dot(map_x,world),dot(map_y,world));
}
void fragment() {
	vec2 wall_uv = (map_position-wall_origin)/wall_size;
	if (any(lessThan(wall_uv,vec2(0.0))) || any(greaterThanEqual(wall_uv,vec2(1.0)))) discard;
	vec4 depth = texture(wall_depth,wall_uv);
	float wall = (round(depth.r*255.0)*256.0+round(depth.g*255.0))/65535.0*3500.0;
	if (depth.a<0.5 || wall<=foot_depth+0.5) discard;
	float alpha = texture(TEXTURE,UV).a;
	if (chroma_key) {
		vec3 source = texture(TEXTURE,UV).rgb;
		float key = smoothstep(0.10,0.34,min(source.r,source.b)-source.g)*(1.0-smoothstep(0.10,0.32,abs(source.r-source.b)));
		alpha *= 1.0-key;
	}
	vec2 px = TEXTURE_PIXEL_SIZE*2.0;
	float inner = min(min(texture(TEXTURE,UV+vec2(px.x,0)).a,texture(TEXTURE,UV-vec2(px.x,0)).a),
		min(texture(TEXTURE,UV+vec2(0,px.y)).a,texture(TEXTURE,UV-vec2(0,px.y)).a));
	COLOR = vec4(silhouette_color.rgb,alpha*mix(silhouette_color.a,0.8,1.0-inner));
}
