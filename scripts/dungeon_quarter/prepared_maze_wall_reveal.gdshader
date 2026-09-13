shader_type canvas_item;
render_mode unshaded;
uniform sampler2D wall_depth : filter_nearest, repeat_disable;
uniform vec2 wall_origin;
uniform vec2 wall_size;
uniform vec2 depth_range;
uniform int wall_pass = 0; // back base, front base, real foreground overlay
uniform int body_count = 0;
uniform vec4 body_rects[128];
uniform float body_feet[128];
uniform float face_opacity = 0.42;
uniform float cap_opacity = 0.72;
void fragment() {
	vec4 packed = texture(wall_depth, UV);
	float code = round(packed.b * 4.0);
	bool front = mod(code, 2.0) > 0.5;
	bool cap = code >= 2.0;
	if (wall_pass < 2 && front != (wall_pass == 1)) discard;
	float encoded = (round(packed.r * 255.0) * 256.0 + round(packed.g * 255.0)) / 65535.0;
	float depth = mix(depth_range.x, depth_range.y, encoded);
	vec2 world = wall_origin + UV * wall_size;
	float reveal = 0.0;
	float nearer_body = -1000000.0;
	for (int i = 0; i < body_count; i++) {
		vec2 distance_from_body = abs(world - body_rects[i].xy) - body_rects[i].zw;
		float edge = max(distance_from_body.x, distance_from_body.y);
		if (edge < -8.0) nearer_body = max(nearer_body, body_feet[i]);
		if (depth > body_feet[i] + 0.5) reveal = max(reveal, 1.0 - smoothstep(0.0, 18.0, edge));
	}
	if (depth <= nearer_body + 0.5) reveal = 0.0;
	if (wall_pass == 2) COLOR.a *= reveal * (cap ? cap_opacity : face_opacity);
	else COLOR.a *= 1.0 - reveal;
}
