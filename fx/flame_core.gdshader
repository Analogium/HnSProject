shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://fx/flame_common.gdshaderinc"

// Le cœur d'une boule de `FlameFx` : marbré du profond au clair, dans un halo qui s'éteint au
// dehors. Poussé au-delà de 1, saturé : la lueur le prend sans le blanchir.

uniform vec3 heart = vec3(1.0, 0.72, 0.22);
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;

const float BOOST = 1.4;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	if (d > 1.0) {
		discard;
	}
	if (d < 0.42) {
		float n = noise(UV * 7.7 + vec2(TIME * 12.8, -TIME * 20.5));
		ALBEDO = mix(mix(tint, deep, 0.35), heart, smoothstep(0.35, 0.7, n + d * 0.6)) * BOOST;
		ALPHA = opacity;
	} else {
		float halo = pow(1.0 - (d - 0.42) / 0.58, 2.0);
		ALBEDO = mix(tint, heart, halo * 0.5) * BOOST;
		ALPHA = halo * 0.75 * opacity;
	}
}
