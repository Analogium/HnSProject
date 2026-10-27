shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Une mouche de la Nuée (`PlagueFx`), par instance d'un `MultiMesh` : un point sombre tourné vers la caméra,
// deux ailes qui battent en reflet clair.

#include "res://fx/flame_common.gdshaderinc"

instance uniform float opacity = 1.0;
varying float seed;

void vertex() {
	seed = float(INSTANCE_ID);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float body = 1.0 - smoothstep(0.35, 0.5, length(d * vec2(1.4, 1.0)));
	float flap = abs(sin(TIME * 60.0 + seed));
	float wings = (1.0 - smoothstep(0.3, 0.45, length(vec2(abs(d.x) - 0.5, d.y * (1.0 + flap))))) * 0.5;
	if (body + wings < 0.05) {
		discard;
	}
	ALBEDO = mix(vec3(0.55, 0.6, 0.5), vec3(0.03, 0.04, 0.02), body);
	ALPHA = clamp(body + wings, 0.0, 1.0) * opacity;
}
