shader_type canvas_item;
// Cosmetic skin recolor for the in-match fighters + creator previews.
// Re-hues a fighter toward a target hue while KEEPING each pixel's value
// (the baked shading/highlights survive) and scaling saturation — the same
// "AI base + algorithmic recolor" idea as scripts/tools/recolor_ralph.py, but
// live in-engine so one shader skins all 7 dinos with no per-skin art.
//
// The hue is forced only where the source pixel is actually colorful: near-
// neutral pixels (cream bellies, teeth, eyes' whites) are left alone so the
// dino still reads as itself, just repainted.

uniform float target_hue = 0.0;          // 0..1 hue to push colored pixels toward
uniform float sat_mul = 1.0;             // saturation multiplier
uniform float val_mul = 1.0;             // value/brightness multiplier
uniform float strength : hint_range(0.0, 1.0) = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(tex.rgb);
	// Only re-hue colorful pixels; keep near-neutral ones (belly, teeth) as-is.
	float colored = smoothstep(0.06, 0.22, hsv.y);
	float blend = strength * colored;
	hsv.x = mix(hsv.x, target_hue, blend);
	hsv.y = clamp(hsv.y * mix(1.0, sat_mul, blend), 0.0, 1.0);
	hsv.z = clamp(hsv.z * mix(1.0, val_mul, strength), 0.0, 1.0);
	vec3 rgb = hsv2rgb(hsv);
	COLOR = vec4(mix(tex.rgb, rgb, strength), tex.a);
}
