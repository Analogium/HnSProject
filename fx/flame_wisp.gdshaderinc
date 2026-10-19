// Une flammèche de `FlameFx` : une volute tournée vers la caméra, rongée par le bruit en
// vieillissant. `opacity` est le réglage des sorts (`Settings.veil`).

#include "res://fx/flame_common.gdshaderinc"

instance uniform float opacity = 1.0;
varying float age;
varying float seed;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	seed = fract(float(INSTANCE_ID) * 0.6180339);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float n = noise(UV * 1.8 + vec2(seed * 179.0, seed * 77.0 - TIME * 9.0));
	float shape = 1.0 - length(q * vec2(1.0, 0.85)) + (n - 0.5) * RAGGED;
	float cut = 0.12 + age * 0.55;
	if (shape < cut) {
		discard;
	}
	float inner = 0.55 + 0.45 * noise(UV * 3.1 + vec2(seed * 128.0, -TIME * 20.0));
	ALBEDO = COLOR.rgb * inner * BOOST * RIM(shape - cut);
	// Nul au bord du quad : le bruit poussait la forme jusqu'aux coins, carrés vus de près.
	ALPHA = smoothstep(0.0, SOFT, shape - cut) * smoothstep(1.0, 0.75, length(q)) * COLOR.a * opacity;
}
