shader_type canvas_item;
render_mode unshaded;
// One analytic pass: no screen reads, texture samples, TIME, blur or loops.
uniform vec2 surface_size = vec2(100.0);
uniform float radius = 16.0;
uniform float halo = 12.0;
uniform float glow_strength = 0.2;
uniform vec4 top_color : source_color = vec4(0.19, 0.13, 0.25, 0.96);
uniform vec4 bottom_color : source_color = vec4(0.06, 0.04, 0.10, 0.96);
uniform vec4 rim_color : source_color = vec4(0.63, 0.48, 0.74, 1.0);
uniform vec4 glow_color : source_color = vec4(0.65, 0.28, 1.0, 1.0);
float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
void fragment() {
	vec2 p = UV * (surface_size + vec2(halo * 2.0)) - vec2(halo);
	float d = rounded_box(p - surface_size * 0.5, surface_size * 0.5 - vec2(1.0), min(radius, surface_size.y * 0.5 - 1.0));
	float inside = 1.0 - smoothstep(-0.6, 0.6, d);
	float rim = 1.0 - smoothstep(0.6, 1.8, abs(d + 0.8));
	float inner = 1.0 - smoothstep(0.6, 1.4, abs(d + 3.0));
	float shine = (1.0 - smoothstep(4.0, 10.0, p.y)) * inside;
	vec4 fill = mix(top_color, bottom_color, clamp(p.y / surface_size.y, 0.0, 1.0));
	// Subtle fixed sheen, kept deterministic and free of noise textures.
	fill.rgb += 0.018 * (1.0 - abs(p.x / surface_size.x * 2.0 - 1.0));
	fill.rgb = mix(fill.rgb, vec3(0.025, 0.016, 0.045), inner * 0.85);
	fill.rgb = mix(fill.rgb, rim_color.rgb, rim);
	fill.rgb += shine * 0.08;
	float glow = (1.0 - smoothstep(0.0, halo, max(d, 0.0)));
	glow = glow * glow * glow_strength;
	COLOR = vec4(mix(glow_color.rgb, fill.rgb, inside), max(glow * (1.0 - inside), fill.a * inside));
}
