shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La lumière que le Pilier sacré pose au sol (`SacredPillarFx`) : forte sous la colonne, douce jusqu'au
// cercle qu'il mord, et un liseré fin au bord — ce qui dit jusqu'où il frappe. Le plan fait 2 de côté,
// mis à l'échelle du rayon ; `column`, le rayon de la colonne, en part du sien.

#include "res://fx/flame_common.gdshaderinc"

uniform vec3 heart = vec3(1.0, 0.82, 0.5);
uniform vec3 tint = vec3(1.0, 0.42, 0.58);
instance uniform float opacity = 1.0;
instance uniform float column = 0.45;
instance uniform float glow = 1.0;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	float d = length(local);
	if (d > 1.0) {
		discard;
	}
	float n = noise(local * 5.0 + vec2(TIME * 0.4, -TIME * 0.6));
	float under = exp(-pow(d / column, 2.0) * 1.5);
	float rim = exp(-pow((d - 0.97) * 40.0, 2.0));
	vec3 c = mix(tint, heart, under) * (under * 0.5 + 0.06 * (0.6 + 0.4 * n)) + tint * rim * 0.45;
	ALBEDO = c * glow * opacity;
}
