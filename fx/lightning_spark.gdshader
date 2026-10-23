shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// L'orbe de `BoltFx` et son étincelle : une boule de plasma et une gerbe d'arcs photographiées
// (`fx/lightning_orb.png`, `fx/lightning_spark.png`) — en feu, la boule et l'explosion de `FlameFx` —,
// tournées vers la caméra, qui tournent ; l'étincelle, grandie, fait aussi l'éclat de fin de course.

#include "res://fx/flame_common.gdshaderinc"
#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_disable;
uniform float boost = 1.0;
uniform float spin = 0.0;
// La case de la photo dans un atlas (la boule de feu en a trois).
uniform vec4 cell = vec4(0.0, 0.0, 1.0, 1.0);
instance uniform float opacity = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float a = TIME * spin;
	vec2 uv = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (UV - 0.5) + 0.5;
	vec3 p = texture(photo, cell.xy + clamp(uv, 0.0, 1.0) * cell.zw).rgb;
	ALBEDO = ramp_of(max(p.r, max(p.g, p.b))) * boost * opacity;
}
