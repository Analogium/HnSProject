shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// L'éclat au cœur du souffle sacré (`HolyBlastFx`) : une gerbe de rayons photographiée par Qwen-Image
// (`fx/holy_flare.png`), tournée vers la caméra, qui éclate et s'éteint. Elle passe par la rampe, le cœur
// blanc en haut.

#include "res://fx/flame_common.gdshaderinc"
#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap;
instance uniform float opacity = 1.0;
instance uniform float glow = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec3 p = texture(photo, UV).rgb;
	float l = max(p.r, max(p.g, p.b));
	ALBEDO = ramp_of(l) * l * glow * opacity;
}
