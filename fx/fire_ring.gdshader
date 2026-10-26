shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Le sol de `FireRing` : une chaleur douce dans le cercle ; le liseré au rayon qui frappe est l'onde de
// feu (`fx/fire_shock.gdshader`). Le plan fait 2 de côté, mis à l'échelle du rayon.

#include "res://fx/flame_common.gdshaderinc"

uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	float d = length(local);
	if (d > 1.0) {
		discard;
	}
	float n = noise(local * 6.0 + vec2(TIME * 0.7, -TIME * 1.1));
	float heat = (0.35 + 0.65 * smoothstep(0.55, 1.0, d)) * (0.6 + 0.4 * n) * smoothstep(1.0, 0.92, d);
	ALBEDO = mix(deep, tint, n) * heat * 0.1 * opacity;
}
