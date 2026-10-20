shader_type canvas_item;
render_mode unshaded;
uniform sampler2D wall_depth : filter_nearest, repeat_disable;
uniform sampler2D actor_texture : filter_linear, repeat_disable;
uniform vec2 wall_origin;
uniform vec2 wall_size;
uniform float foot_depth;
uniform vec4 silhouette_color : source_color;
uniform bool chroma_key = false;
uniform vec3 map_x;
uniform vec3 map_y;
uniform vec4 frame_uv = vec4(0.0,0.0,1.0,1.0);
varying vec2 map_position;
float body_alpha(vec2 uv) {
	if (any(lessThan(uv,frame_uv.xy)) || any(greaterThanEqual(uv,frame_uv.zw))) return 0.0;
	vec4 source = texture(actor_texture,uv);
	float alpha = source.a;
	if (chroma_key) {
		float key = smoothstep(0.10,0.34,min(source.r,source.b)-source.g)*(1.0-smoothstep(0.10,0.32,abs(source.r-source.b)));
		alpha *= 1.0-key;
	}
	return alpha;
}
void vertex() {
	vec3 world = vec3((MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy,1.0);
	map_position = vec2(dot(map_x,world),dot(map_y,world));
}
void fragment() {
	vec2 dx = dFdx(UV)*2.0;
	vec2 dy = dFdy(UV)*2.0;
	vec2 wall_uv = (map_position-wall_origin)/wall_size;
	if (any(lessThan(wall_uv,vec2(0.0))) || any(greaterThanEqual(wall_uv,vec2(1.0)))) discard;
	vec4 depth = texture(wall_depth,wall_uv);
	float wall = (round(depth.r*255.0)*256.0+round(depth.g*255.0))/65535.0*3500.0;
	if (depth.a<0.5 || wall<=foot_depth+0.5) discard;
	// Inward contour in screen pixels: never expand or fill the actor's body.
	float alpha = body_alpha(UV);
	float inner = min(min(body_alpha(UV+dx),body_alpha(UV-dx)),min(body_alpha(UV+dy),body_alpha(UV-dy)));
	inner = min(inner,min(min(body_alpha(UV+(dx+dy)*0.7071),body_alpha(UV-(dx+dy)*0.7071)),
		min(body_alpha(UV+(dx-dy)*0.7071),body_alpha(UV-(dx-dy)*0.7071))));
	if (alpha<0.1 || inner>=0.1) discard;
	COLOR = vec4(silhouette_color.rgb,silhouette_color.a*alpha);
}
