shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Les scintillements de la Nova (`IceNovaFx`) : une étoile à quatre branches tournée vers la caméra, par
// instance d'un `MultiMesh` ; son éclat dans le rouge de `INSTANCE_CUSTOM`. C'est de la lumière : elle
// s'additionne, petite, sans blanchir le cercle.

#include "res://fx/flame_common.gdshaderinc"

uniform vec3 rime;
instance uniform float opacity = 1.0;

varying float shine;

void vertex() {
	shine = INSTANCE_CUSTOM.r;
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float star = max(1.0 - abs(d.x) * 6.0 - abs(d.y) * 0.9, 0.0) + max(1.0 - abs(d.y) * 6.0 - abs(d.x) * 0.9, 0.0);
	ALBEDO = rime * 0.9;
	ALPHA = clamp(star * 0.8 + exp(-dot(d, d) * 18.0), 0.0, 1.0) * shine * opacity;
}
