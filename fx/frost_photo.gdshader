shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// L'orbe du Trait de glace (`BoltFx` en froid) et son éclatement : des photos de glace
// (`fx/frost_orb.png`, `fx/frost_burst.png`), tournées vers la caméra, qui tournent. **Mêlées, pas
// additionnées** : le cyan ajouté à l'ocre sortait blanc — le froid s'ombre.

#include "res://fx/flame_common.gdshaderinc"
#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_disable;
uniform float spin = 0.0;
// Sous 0,85 : le cœur blanc de la rampe ne vient pas.
uniform float level = 0.68;
instance uniform float opacity = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float a = TIME * spin;
	vec2 uv = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (UV - 0.5) + 0.5;
	vec3 p = texture(photo, clamp(uv, 0.0, 1.0)).rgb;
	float l = max(p.r, max(p.g, p.b));
	ALBEDO = ramp_of(l * level);
	ALPHA = clamp(l * 1.45, 0.0, 1.0) * opacity;
}
