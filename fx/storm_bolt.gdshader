shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// L'éclair du Nuage d'orage (`StormCloudFx`) : le tronc d'un éclair photographié (`fx/storm_bolt.png`,
// son voile coupé), tourné vers la caméra, posé par son pied. Une verticale du monde reste verticale
// à l'écran sous la caméra du jeu.

#include "res://fx/flame_common.gdshaderinc"
#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_disable;
uniform float boost = 1.3;
instance uniform float opacity = 1.0;
// Retourné une fois sur deux : deux éclairs voisins ne se ressemblent pas.
instance uniform float flip = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float l = texture(photo, vec2(flip > 0.5 ? 1.0 - UV.x : UV.x, UV.y)).r;
	ALBEDO = ramp_of(l) * boost * opacity;
}
