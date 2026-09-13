shader_type canvas_item;
render_mode unshaded;
uniform sampler2D wall_depth : filter_nearest, repeat_disable;
uniform vec2 wall_origin;
uniform vec2 wall_size = vec2(1.0);
uniform vec2 depth_range;
uniform float foot_depth;
uniform vec3 map_x = vec3(1.0, 0.0, 0.0);
uniform vec3 map_y = vec3(0.0, 1.0, 0.0);
uniform bool chroma_key = false;
uniform bool occlusion_enabled = true;
varying vec2 map_position;
void vertex() {
	vec3 world = vec3((MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy, 1.0);
	map_position = vec2(dot(map_x, world), dot(map_y, world));
}
void fragment() {
	vec2 wall_uv = (map_position - wall_origin) / wall_size;
	if (occlusion_enabled && all(greaterThanEqual(wall_uv, vec2(0.0))) && all(lessThan(wall_uv, vec2(1.0)))) {
		vec4 sample_depth = texture(wall_depth, wall_uv);
		float encoded = (round(sample_depth.r * 255.0) * 256.0 + round(sample_depth.g * 255.0)) / 65535.0;
		float depth = mix(depth_range.x, depth_range.y, encoded);
		if (sample_depth.a > 0.5 && depth > foot_depth + 0.5) discard;
	}
	if (chroma_key) {
		vec3 source = texture(TEXTURE, UV).rgb;
		float key = smoothstep(0.10, 0.34, min(source.r, source.b) - source.g) * (1.0 - smoothstep(0.10, 0.32, abs(source.r - source.b)));
		COLOR.a *= 1.0 - key;
	}
}
