shader_type canvas_item;
render_mode unshaded, blend_disabled;
// Store 16-bit depth as two raw bytes. This also works without HDR rendering.
void fragment() {
	float depth = floor(clamp(UV.x, 0.0, 1.0) * 65535.0 + 0.5);
	COLOR = vec4(floor(depth / 256.0) / 255.0, mod(depth, 256.0) / 255.0, 0.0, 1.0);
}
