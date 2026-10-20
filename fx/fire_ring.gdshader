shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Le sol de `FireRing` : une chaleur douce dans le cercle, et un liseré de feu qui vacille au
// rayon qui frappe. Le plan fait 2 de côté, mis à l'échelle du rayon.

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
	float m = noise(vec2(atan(local.y, local.x) * 6.0, TIME * 3.0));
	float line = (1.0 - smoothstep(0.0, 0.025 + 0.02 * m, abs(d - 0.96))) * (0.5 + 0.7 * m);
	ALBEDO = (mix(deep, tint, n) * heat * 0.1 + mix(tint, vec3(1.0, 0.8, 0.4), m * 0.4) * line) * opacity;
}
