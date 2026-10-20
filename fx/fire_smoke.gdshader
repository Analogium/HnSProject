shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La fumée d'une explosion de `FlameFx` : une photo de fumée tirée sur fond blanc, sa densité
// en R, mêlée sous le feu à la couleur de la particule.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
instance uniform float opacity = 1.0;
varying float seed;

void vertex() {
	seed = fract(float(INSTANCE_ID) * 0.6180339);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float a = seed * 6.28 + TIME * 0.4;
	vec2 uv = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (UV - 0.5) + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		discard;
	}
	ALBEDO = COLOR.rgb;
	ALPHA = texture(atlas, uv).r * COLOR.a * 1.6 * opacity;
}
